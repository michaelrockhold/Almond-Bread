//
//  ImageDataReadyView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/25/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImageDataReadyView: View {
    @ObservedObject var imageInfoViewModel: ImageInfoViewModel

    var body: some View {
        if let img = imageInfoViewModel.fullImage {
            img
            .resizable()
            .aspectRatio(contentMode: .fit)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ShareLink(item: self.imageInfoViewModel,
                              preview: SharePreview(
                                "Almond Bread Image",
                                image: imageInfoViewModel.thumbnail
                                ))
                    .disabled(self.imageInfoViewModel.renderedImage == nil)
                }
            }
        }
        else {
            Image(systemName: "exclamationmark.transmission")
        }
    }
}

extension ImageInfoViewModel: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { $0.jpegData! }
    }
    
    var fullImage: Image? {
        guard let image = self.renderedImage else {
            return nil
        }
        return Image(decorative: image, scale: 1.0, orientation: .up)
    }
    
    var thumbnail: Image {
        guard let cgImage = self.renderedImage else {
            return Image(systemName: "exclamationmark.circle")
        }
        return Image(decorative: cgImage, scale: 0.10)
    }
}


//#Preview {
//    ImageDataReadyView()
//}
