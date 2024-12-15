//
//  Calculator.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/24/24.
//

import Foundation
import SwiftUI

actor Calculator {

    public enum CalculatorError: Error {
        case cancelled
    }
    
    typealias CompletionHandler = ([PointResult])->Void
    typealias CalculationTask = Task<Void, Error>
    typealias ProgressFn = (Int)->Void
    typealias OuterCompletionHandler = ([PointResult], Settings)->Void
    typealias InnerCompletionHandler = ([PointResult], Settings)->Void

    typealias Calculation = ([PointResult], Settings)
    
    struct Settings: Equatable {
        struct ImageDimensions: Equatable {
            let width: Int
            let height: Int
        }
        struct Point: Equatable {
            let x: Double
            let y: Double
        }
        let imageDimensions: ImageDimensions
        let center: Point
        let maxIter: Int
        let pixelSize: Double
    }

    struct PointResult {
        var count: Int = 0
        var radiusSquared: Double = 0.0
    }

    func calculate(settings: Settings, progressHandler: @escaping ProgressFn) async -> Result<Calculation, Error> {

        let arraySize = settings.imageDimensions.height * settings.imageDimensions.width
        var counts = [PointResult](repeating: PointResult(), count: arraySize)

        var progress = 0
        return await _calculate(settings: settings,
                                xrange: 0..<settings.imageDimensions.width,
                                yrange: 0..<settings.imageDimensions.height,
                                counts: &counts) { incr in
            progress += incr
            progressHandler(progress)
        }
    }

    private func _calculate(settings: Settings,
                            xrange: Range<Int>,
                            yrange: Range<Int>,
                            counts: inout [PointResult],
                            progressHandler: @escaping ProgressFn) async -> Result<Calculation, Error> {
        
        let offsetX = settings.center.x - Double(settings.imageDimensions.width) * settings.pixelSize / 2.0
        let offsetY = settings.center.y + Double(settings.imageDimensions.height) * settings.pixelSize / 2.0
        
        let threshold = Double(1<<16) // 65K

        func translateCoord(x: Int, y: Int) -> (Double, Double) {
            return (offsetX + Double(x) * settings.pixelSize,
                    offsetY - Double(y) * settings.pixelSize)
        }
        
        @Sendable func iterate(x0: Double, y0: Double) -> PointResult {
            
            func update(zx: Double, zy: Double, zx2: Double, zy2: Double) -> (Double, Double) {
                return (zx2 - zy2 + x0, 2 * zx * zy + y0)
            }

            var zx = 0.0
            var zy = 0.0
            for c in 0 ..< settings.maxIter {
                let zx2 = zx * zx
                let zy2 = zy * zy
                let radius2 = zx2 + zy2

                if radius2 >= threshold {
                    return PointResult(count: c, radiusSquared: radius2)
                }
                    
                (zx, zy) = update(zx: zx, zy: zy, zx2: zx2, zy2: zy2)
            }
            // fall through; this may be in the set
            return PointResult(count: settings.maxIter)
        }

        var counter = 0
        progressHandler(counter)

        for x in xrange.lowerBound ..< xrange.upperBound {
            for y in yrange.lowerBound ..< yrange.upperBound {
                let (x0, y0) = translateCoord(x: x, y: y)
                counts[y * settings.imageDimensions.width + x] = iterate(x0: x0, y0: y0)
                counter += 1
                if counter % 60 == 0 {
                    progressHandler(counter)
                    counter = 0
                }
                if Task.isCancelled {
                    return .failure(CalculatorError.cancelled)
                }
            }
        }
        if counter > 0 {
            progressHandler(counter)
        }
        return .success(Calculation(counts, settings))
    }
}
