//
//  ImageDataReadyView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/25/24.
//

import SwiftUI

struct ImageDataReadyView: View {
    @State var imageInfoViewModel: ImageInfoViewModel

    var body: some View {
        if let imageData = imageInfoViewModel.imageInfo.imageData {
            let provider = CGDataProvider(data: imageData as CFData)!
            if let image = CGImage(width: Int(imageInfoViewModel.imageInfo.imageWidth),
                                   height: Int(imageInfoViewModel.imageInfo.imageHeight),
                                   bitsPerComponent: IntPixel.componentBitSize,
                                   bitsPerPixel: IntPixel.bitSize,
                                   bytesPerRow: Int(imageInfoViewModel.imageInfo.imageWidth) * IntPixel.byteSize,
                                   space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                   bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                                   provider: provider,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: .defaultIntent) {

                Image(decorative: image, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("ERROR (2)")
            }
        } else {
            Text("ERROR (1)")
        }
    }
}

//#Preview {
//    ImageDataReadyView()
//}
