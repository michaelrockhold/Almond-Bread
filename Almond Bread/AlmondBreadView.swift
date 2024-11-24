//
//  AlmondBreadView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/17/24.
//

import SwiftUI

extension Pixel<UInt8> {
    static func white() -> Pixel<UInt8> {
        return Pixel<UInt8>(red: 0, green: 0, blue: 0, alpha: 255)
    }
    static func black() -> Pixel<UInt8> {
        return Pixel<UInt8>(red: 255, green: 255, blue: 255, alpha: 255)
    }

    init(r: Double, g: Double, b: Double) {
        func clrInt(_ c: Double) -> UInt8 {
            let ic = Int(round(0x100 * c))
            if ic < 0 {
                return 0
            } else if ic > 255 {
                return 255
            } else {
                return UInt8(ic)
            }
        }

        self.init(red: clrInt(r), green: clrInt(g), blue: clrInt(b), alpha: 255)
    }

}

struct AlmondBreadView: View {

    @State var cgImage: CGImage? = nil
    @State var progress: Double = 0.0

    var imageView: Image {
        if let image = cgImage {
            Image(decorative: image, scale: 1.0, orientation: .up)
        } else {
            Image(size: CGSize(width: 640.0, height: 480.0)) { (gc: inout GraphicsContext) in
                let p = Path(CGRect(x: 0, y: 0, width: 640, height: 480))
                gc.fill(p, with: .color(.red))
                gc.draw(Text("Hello, World"), in: CGRect(x: 0, y: 0, width: 640, height: 480))
            }
        }
    }

    typealias IntPixel = Pixel<UInt8>

    var body: some View {

        if progress < 1.0 {
            ProgressView(value: progress)
                .progressViewStyle(.circular)
                .padding(20)
                .task {
                    let width = 800
                    let height = 600
                    let pxl = IntPixel(red: 127, green: 0, blue: 127, alpha: 255)
                    var bytes = [IntPixel](repeating: pxl, count: width*height)

                    var plotter = Plotter(width: width, height: height,
                                          centerX: -0.7412067031270126, centerY: -0.1207678370473447,
                                          pixelSize: 1.0940668476076224e-11,
                                          maxIter: 1000,
                                          scheme: .classic,
                                          progress: $progress
                                          )

                    await plotter.plotImage { (x, y, pixel) in
                        bytes[y * width + x] = IntPixel(r: pixel.0, g: pixel.1, b: pixel.2)
                    }

                    bytes.withUnsafeMutableBufferPointer { (b: inout UnsafeMutableBufferPointer<IntPixel>) in
                        let data = Data(buffer: b)
                        let provider = CGDataProvider(data: data as CFData)!
                        self.cgImage = CGImage(width: width,
                                               height: height,
                                               bitsPerComponent: IntPixel.componentBitSize,
                                               bitsPerPixel: IntPixel.bitSize,
                                               bytesPerRow: width * IntPixel.byteSize,
                                               space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                               provider: provider,
                                               decode: nil,
                                               shouldInterpolate: false,
                                               intent: .defaultIntent)
                    }
                }
        } else {
            self.imageView
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

#Preview {
    AlmondBreadView()
}
