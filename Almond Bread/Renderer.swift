//
//  Renderer.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/24/24.
//

import Foundation

import SwiftUI

extension Double {
    // Linear interpolate
    func lerp(other: Double, frac: Double) -> Double {
        return self + ((other - self) * frac)
    }
}

struct Renderer {
    public enum Scheme: Int, CaseIterable, Identifiable, CustomStringConvertible {
        case classic = 0
        case wikipedia = 1

        var id: Self { self }

        var description: String {
            switch self {
            case .classic:
                return "Warm"
            case .wikipedia:
                return "Cool"
            }
        }

    }

    struct ColorScheme {
        // Source: Paul Bourke
        static var CLASSIC: [ClrControl] {
            [
                ClrControl(0.00, 0.0, 0.0, 1.0),
                ClrControl(0.25, 0, 1, 1),
                ClrControl(0.50, 0, 1, 0),
                ClrControl(0.75, 1, 1, 0),
                ClrControl(1.00, 1, 0, 0),
            ]
        }

        // SRC: https://stackoverflow.com/questions/16500656#25816111
        static var WIKIPEDIA_CLR: [ClrControl] {
            [
                ClrControl(0.000000, 0.000000, 0.027451, 0.392157),
                ClrControl(0.160000, 0.125490, 0.419608, 0.796078),
                ClrControl(0.420000, 0.929412, 1.000000, 1.000000),
                ClrControl(0.642500, 1.000000, 0.666667, 0.000000),
                ClrControl(0.857500, 0.000000, 0.007843, 0.000000),
                ClrControl(1.000000, 0.400000, 0.400000, 1.000000),
            ]
        };

        static var scheme: [[ClrControl]] {
            [Self.WIKIPEDIA_CLR, Self.CLASSIC]
        }
    }

    struct ClrControl {
        let ctrl: Double
        let fpixel: Pixel<Double>

        init(ctrl: Double, fpixel: Pixel<Double>) {
            self.ctrl = ctrl
            self.fpixel = fpixel
        }

        init(_ ctrl: Double, _ red: Double, _ green: Double, _ blue: Double) {
            self.init(ctrl: ctrl, fpixel: Pixel<Double>(red: red, green: green, blue: blue, alpha: 1.0))
        }
    }

    private let maxIterations: Int
    private let colorScheme: [ClrControl]

    init(maxIterations: Int,
         scheme: Renderer.Scheme
    ) {
        self.maxIterations = maxIterations
        self.colorScheme = ColorScheme.scheme[scheme.rawValue]
    }

    func plotImage(counts: [Calculator.PointResult]) -> [Pixel<UInt8>] {
        return plotImage(
            counts: counts,
            palette: calculatePalette(counts: counts))
    }

    private func plotImage(counts: [Calculator.PointResult],
                           palette: [Double]) -> [Pixel<UInt8>] {

        func ratio(for pr: Calculator.PointResult) -> Double {
            let log2 = log(2.0)

            if pr.count < maxIterations  {
                let log_zn = log(pr.radiusSquared) / 2.0
                let nu = log(log_zn / log2) / log2
                let fcount = Double(pr.count) + 1.0 - nu
                let ifcf = floor(fcount)
                let ifc = ifcf.isNaN ? Int.min : Int(ifcf)

                // Sanity check: we may have exceeded the check if
                // we've gotten too far from the set.  In that case,
                // color it white:
                if ifc < 0 || ifc >= maxIterations -  1 {
                    return 1.0

                } else {
                    return palette[ ifc ].lerp(other: palette[ ifc + 1], frac: fcount - ifcf)
                }
            } else {
                return 1.0
            }
        }

        return counts.map { pr in
            return Pixel<UInt8>(doublePixel: colour(for: ratio(for: pr), colorScheme: colorScheme))
        }
    }

    func colour(for _ratio: Double, colorScheme: [ClrControl]) -> Pixel<Double> {

        guard _ratio < 1 else { return .white }     // return white; The set itself is black
        let ratio = _ratio <= 0 ? 0.0001 : _ratio            // Should never happen w/o FP errors.

        // First iteration needed for setting o{ctrl,r,g,b}.
        var colorPoint0 = colorScheme.first!

        // for remaining iterations:
        for colorPoint in colorScheme.dropFirst() {
            if ratio < colorPoint.ctrl {
                return colorPoint0.fpixel.lerp(colorPoint.fpixel,
                                               frac: (ratio - colorPoint0.ctrl) / (colorPoint.ctrl - colorPoint0.ctrl))
            } else { // reset control-point
                colorPoint0 = colorPoint
            }
        }
        // fell through?
        return .black
    }

    private func calculatePalette (counts: [Calculator.PointResult]) -> [Double] {
        // Create a histogram of counts
        var hist = [Int](repeating: 0, count: maxIterations)

        // Exclude items that reached the escape
        // (i.e. are probably members of the Mandelbrot set) as they skew
        // the colouring.
        for pc in counts {
            if pc.count >= maxIterations  {
                continue  // members skew the results
            }
            hist[ pc.count ] += 1
        }

        // Compute the total
        let total = hist.reduce(into: 0) { partialResult, h in
            partialResult += h
        }

        // Now, create the palette
        var palette = [Double]()
        var hue = 0.0
        for h in hist  {
            palette.append(hue)
            hue += Double(h) / Double(total)
        }

        return palette
    }
}
