//
//  Calculator.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/24/24.
//

import Foundation
import SwiftUI

actor Calculator {

    typealias CompletionHandler = ([PointResult])->Void
    typealias CalculationTask = Task<Void, Error>
    typealias ProgressFn = (Int)->Void
    typealias OuterCompletionHandler = ([PointResult], Settings)->Void
    typealias InnerCompletionHandler = ([PointResult], Settings)->Void

    struct Settings: Equatable {
        let width: Int
        let height: Int
        let maxIter: Int
        let x: Double
        let y: Double
        let pixelSize: Double

        init(width: Int, height: Int,
             centerX:Double, centerY: Double,
             pixelSize: Double,
             maxIter: Int
        ) {
            self.width = width
            self.height = height

            self.x = centerX // - (Double(width) / 2.0 * pixelSize)
            self.y = centerY // + (Double(height) / 2.0 * pixelSize)
            self.pixelSize = pixelSize
            self.maxIter = maxIter
        }

        static var zero: Settings {
            return Settings(width: 0, height: 0, centerX: 0.0, centerY: 0.0, pixelSize: 0.0, maxIter: 0)
        }
    }

    struct PointResult {
        var count: Int = 0
        var radiusSquared: Double = 0.0
    }

    func calculate(settings: Settings, progressHandler: @escaping ProgressFn, onComplete: @escaping OuterCompletionHandler) async {


        await _calculate(settings: settings, range: 0..<(settings.height * settings.width),
                                             progressHandler: progressHandler) { (points, settings) in
            // trampoline because we will shortly be adding more tasks
            onComplete(points, settings)
        }
    }

    private func _calculate(settings: Settings,
                            range: Range<Int>,
                            progressHandler: @escaping ProgressFn,
                            onComplete: @escaping InnerCompletionHandler) async {

        @Sendable func countAt (px: Int, py: Int) -> PointResult {
            var zx = 0.0
            var zy = 0.0
            let x0 = settings.x + Double(px) * settings.pixelSize
            let y0 = settings.y - Double(py) * settings.pixelSize

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

        let stride = settings.width
        var counts = [PointResult]()

        progressHandler(range.lowerBound)

        for i in range.lowerBound ..< range.upperBound {
            counts.append(countAt(px: i % stride, py: i / stride))
            if i % 60 == 0 {
                progressHandler(i)
            }
            if Task.isCancelled {
                return
            }
        }
        progressHandler(range.upperBound)
        onComplete(counts, settings)
    }
}
