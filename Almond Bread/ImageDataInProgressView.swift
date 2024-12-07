//
//  CountDataNotReadyView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import SwiftUI

struct ImageDataInProgressView: View {
    @State public var imageInfoViewModel: ImageInfoViewModel

    var body: some View {
        HStack {
            ProgressView(value: imageInfoViewModel.countGenerationProgress)
                .progressViewStyle(.circular)
                .padding(20)
            
            ProgressView(value: imageInfoViewModel.imageGenerationProgress)
                .progressViewStyle(.circular)
                .padding(20)
        }
    }
}

//#Preview {
//    CountDataNotReadyView(msg: "PREVIEW")
//}
