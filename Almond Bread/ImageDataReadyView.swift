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
        if let image = imageInfoViewModel.renderedImage {
            Image(decorative: image, scale: 1.0, orientation: .up)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "exclamationmark.transmission")
        }
    }
}

//#Preview {
//    ImageDataReadyView()
//}
