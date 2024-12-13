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

        return await _calculate(settings: settings,
                                range: 0..<arraySize,
                                counts: &counts,
                                progressHandler: progressHandler)
    }

    private func _calculate(settings: Settings,
                            range: Range<Int>,
                            counts: inout [PointResult],
                            progressHandler: @escaping ProgressFn) async -> Result<Calculation, Error> {

        @Sendable func countAt (px: Int, py: Int) -> PointResult {
            var zx = 0.0
            var zy = 0.0
            let x0 = settings.center.x + Double(px) * settings.pixelSize
            let y0 = settings.center.y - Double(py) * settings.pixelSize

            var zxzx = 0.0
            var zyzy = 0.0
            for c in 0 ..< settings.maxIter {
                zxzx = zx*zx
                zyzy = zy*zy

                if zxzx + zyzy >= Double(1<<16) {
                    return PointResult(count: c, radiusSquared: zxzx + zyzy)
                }

                let xtmp = zxzx - zyzy + x0
                zy = 2*zx*zy + y0
                zx = xtmp
            }

            return PointResult(count: settings.maxIter, radiusSquared: zxzx + zyzy)
        }

        let stride = settings.imageDimensions.width

        progressHandler(range.lowerBound)

        for i in range.lowerBound ..< range.upperBound {
            counts[i] = countAt(px: i % stride, py: i / stride)
            if i % 60 == 0 {
                progressHandler(i)
            }
            if Task.isCancelled {
                return .failure(CalculatorError.cancelled)
            }
        }
        progressHandler(range.upperBound)
        return .success(Calculation(counts, settings))
    }
}
