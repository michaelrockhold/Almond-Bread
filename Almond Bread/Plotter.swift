//
//  Plotter.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/19/24.
//

import Foundation
import SwiftUI

struct Plotter {
    public enum Scheme: Int {
        case classic = 0
        case wikipedia = 1
    }

    private let width: Int
    private let height: Int
    private let colorScheme: [ClrControl]

    private let x: Double
    private let y: Double
    private let pixelSize: Double
    private let maxIter: Int

    @Binding private var progress: Double

    init(width: Int, height: Int,
         centerX:Double, centerY: Double,
         pixelSize: Double,
         maxIter: Int,
         scheme: Plotter.Scheme,
         progress: Binding<Double>
    ) {
        self.width = width
        self.height = height
        self.colorScheme = ColorScheme.scheme[scheme.rawValue]

        self.x = centerX - (Double(width) / 2.0 * pixelSize)
        self.y = centerY + (Double(height) / 2.0 * pixelSize)
        self.pixelSize = pixelSize
        self.maxIter = maxIter
        self._progress = progress
    }

    mutating func plotImage(setPixel: (Int, Int, (Double, Double, Double))->Void) async {

        progress = 0.0
        var results = [PointResult]()
        createCounts(counts: &results)

        let palette = calculatePalette(results: &results)

        colorImg(
            results: results,
            palette: palette,
            setPixel: setPixel)
        progress = 1.0
    }

    struct ColorScheme {
        // Source: Paul Bourke
        static var CLASSIC: [ClrControl] {
            [
                ClrControl.init(0.00, 0.0, 0.0, 1.0),
                ClrControl(0.25, 0, 1, 1),
                ClrControl(0.50, 0, 1, 0),
                ClrControl(0.75, 1, 1, 0),
                ClrControl(1.00, 1, 0, 0),

                ClrControl(999.0, 0, 0, 0)
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
                ClrControl(999.0, 0, 0, 0)
            ]
        };

        static var scheme: [[ClrControl]] {
            [Self.WIKIPEDIA_CLR, Self.CLASSIC]
        }
    }

    struct PointResult {
        var count: Int = 0
        var radiusSquared: Double = 0.0
    }

    // Linear interpolate
    private static func lerp(a: Double, b: Double, frac: Double) -> Double {
        return a + ((b - a) * frac)
    }

    private mutating func colorImg(results: [PointResult],
                                   palette: [Double],
                                   setPixel: (Int, Int, (Double, Double, Double))->Void) {

        func color(for pr: PointResult) -> Double {
            let log2 = log(2.0)

            if pr.count < maxIter  {
                let log_zn = log(pr.radiusSquared) / 2.0
                let nu = log(log_zn / log2) / log2
                let fcount = Double(pr.count) + 1.0 - nu
                let ifcf = floor(fcount)
                let ifc = ifcf.isNaN ? Int.min : Int(ifcf)

                // Sanity check: we may have exceeded the check if
                // we've gotten too far from the set.  In that case,
                // color it white:
                if ifc < 0 || ifc >= maxIter -  1 {
                    return 1.0

                } else {
                    let clr1 = palette[ ifc ]
                    let clr2 = palette[ ifc + 1]
                    let frac = fcount - ifcf
                    return Self.lerp(a: clr1, b: clr2, frac: frac)
                }
            } else {
                return 1.0
            }
        }

        for (i,pr) in results.enumerated() {
            setPixel(i % self.width, i / self.width, colourFor(ratio: color(for: pr), colorScheme: colorScheme))
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

    func colourFor (ratio _ratio: Double, colorScheme: [ClrControl]) -> (Double, Double, Double) {

        var ratio = _ratio
        if (ratio >= 1) { return (0.0, 0.0, 0.0) }     // return white; The set itself is black
        if (ratio <= 0) { ratio = 0.0001 } // Should never happen w/o FP errors.

        var n = 0
        var or = 0.0
        var og = 0.0
        var ob = 0.0
        var octrl = 0.0

        while colorScheme[n].ctrl < 99.0 {
            if (n > 0 &&    // First iteration needed for setting o{ctrl,r,g,b}.
                ratio < colorScheme[n].ctrl) {

                let frac = (ratio - octrl) / (colorScheme[n].ctrl - octrl)
                return (
                    r: Self.lerp(a: or, b: colorScheme[n].fpixel.red, frac: frac),
                    g: Self.lerp(a: og, b: colorScheme[n].fpixel.green, frac: frac),
                    b: Self.lerp(a: ob, b: colorScheme[n].fpixel.blue, frac: frac)
                )
            } else {
                octrl = colorScheme[n].ctrl;
                or = colorScheme[n].fpixel.red;
                og = colorScheme[n].fpixel.green;
                ob = colorScheme[n].fpixel.blue;
            }
            n += 1
        }

        return (1.0, 1.0, 1.0)
    }

    private mutating func calculatePalette (results: inout [PointResult]) -> [Double] {
        // Create a histogram of counts
        var hist = [Int](repeating: 0, count: maxIter)

        for n in 0 ..< self.width * self.height {
            if results[n].count >= maxIter  {
                continue  // members skew the results
            }
            hist[ results[n].count ] += 1
        }

        // Compute the total, excluding items that reached the escape
        // (i.e. are probably members of the Mandelbrot set) as they skew
        // the colouring.
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


    private mutating func createCounts(counts: inout [PointResult]) {

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

    /*
     static void
     createCountsRange(pos: Position, firstRow: Int, lastRow: Int) {

     assert(firstRow < pos.height && lastRow < pos.height);

     const int dotFreq = 1 + (pos.width * pos.height) / 100;

     int curr = firstRow * pos.width;
     for (int yy = firstRow; yy <= lastRow; yy++) {
     for (int xx = 0; xx < pos.width; xx++) {
     self.results[curr++] = countAt(pos.x, pos.y, xx, yy, pos.pixelSize,
     pos.maxItr);

     if (curr % dotFreq == 0) {
     fputs(".", stdout);
     fflush(stdout);
     }// if
     }// for
     }// for
     fputs("\n", stdout);
     }// createCountsRange

     PointResult *
     createCounts(int nthreads) {

     if (pos.height < 3 * nthreads) {
     printf("%d threads for %d rows is too low; going single-threaded.",
     nthreads, pos.height);
     nthreads = 1;
     }// if





     pthread_t threadlist[nthreads];
     CountArgs args[nthreads];

     int incr = pos.height / nthreads + 1;
     for (int firstRow = 0, n = 0; n < nthreads && firstRow < pos.height; n++) {
     int lastRow = firstRow + incr;
     lastRow = lastRow < pos.height ? lastRow : pos.height - 1;

     args[n] = (CountArgs){pos, firstRow, lastRow, counts};

     if (nthreads == 1) {
     createCountsRange(&args[n]);
     } else {
     int stat = pthread_create(&threadlist[n], NULL,
     (void *(*)(void*))createCountsRange,
     (void*) &args[n]);
     if (stat) {
     printf("Error launching thread: %s\n", strerror(stat));
     exit(1);
     }// if
     }

     firstRow += incr;
     }// for

     if (nthreads == 1) {
     // No need to join; just return.
     return counts;
     }

     for (int n = 0; n < nthreads; n++) {
     pthread_join(threadlist[n], NULL);
     }

     return counts;
     }// createCounts
     */

}
