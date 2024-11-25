//
//  Calculator.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/24/24.
//

import Foundation
import SwiftUI

struct Calculator {

    struct PointResult {
        var count: Int = 0
        var radiusSquared: Double = 0.0
    }

    public let width: Int
    public let height: Int
    public let maxIter: Int
    
    private let x: Double
    private let y: Double
    private let pixelSize: Double

    @Binding private var progress: Double

    init(width: Int, height: Int,
         centerX:Double, centerY: Double,
         pixelSize: Double,
         maxIter: Int,
         progress: Binding<Double>
    ) {
        self.width = width
        self.height = height

        self.x = centerX - (Double(width) / 2.0 * pixelSize)
        self.y = centerY + (Double(height) / 2.0 * pixelSize)
        self.pixelSize = pixelSize
        self.maxIter = maxIter
        self._progress = progress
    }


    func calculate(counts: inout [PointResult]) async {

        func countAt (px: Int, py: Int) -> PointResult {
            var zx = 0.0
            var zy = 0.0
            let x0 = x + Double(px) * pixelSize
            let y0 = y - Double(py) * pixelSize

            var zxzx = 0.0
            var zyzy = 0.0
            for c in 0 ..< maxIter {
                zxzx = zx*zx
                zyzy = zy*zy

                if zxzx + zyzy >= Double(1<<16) {
                    return PointResult(count: c, radiusSquared: zxzx + zyzy)
                }

                let xtmp = zxzx - zyzy + x0
                zy = 2*zx*zy + y0
                zx = xtmp
            }

            return PointResult(count: maxIter, radiusSquared: zxzx + zyzy)
        }

        let total = self.width * self.height
        let alreadyCalculated = counts.count

        for i in alreadyCalculated ..< total {
            counts.append(countAt(px: i % self.width, py: i / self.width))
            if i % 60 == 0 {
                progress = Double(i)/Double(total)
            }

            // TODO: check for cancellation
        }
        progress = 1.0
    }
}
