//
//  AlmondBreadView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/17/24.
//

import SwiftUI

struct AlmondBreadView: View {

    //    @State var cgImage: CGImage? = nil
    @State private var isShowingSheet = false
    @StateObject var imageInfoViewModel: ImageInfoViewModel

    init(imageInfo: ImageInfo) {
        self._imageInfoViewModel = StateObject<ImageInfoViewModel>(wrappedValue: ImageInfoViewModel(imageInfo: imageInfo))
    }

    var body: some View {

        ZStack {
            switch (imageInfoViewModel.countDataReady, imageInfoViewModel.imageDataReady) {
            case (false, _):
                ProgressView(value: imageInfoViewModel.countGenerationProgress)
                    .progressViewStyle(.circular)
                    .padding(20)
            case (true, true):
                ImageDataReadyView(imageInfoViewModel: imageInfoViewModel)
            case (true, false):
                ImageDataNotReadyView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Adjust Parameters", systemImage: "gearshape") {
                    isShowingSheet.toggle()
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            AdjustSettingsView(name: imageInfoViewModel.imageInfo.name ?? "") { newName in
                if newName != imageInfoViewModel.imageInfo.name {
                    imageInfoViewModel.countDataReady = false
                    imageInfoViewModel.imageInfo.name = newName
                    try? imageInfoViewModel.imageInfo.managedObjectContext?.save()
                }
            }
        }
        .onAppear() {
            isShowingSheet = true
        }



        //            Image(size: CGSize(width: 640.0, height: 480.0)) { (gc: inout GraphicsContext) in
        //                let p = Path(CGRect(x: 0, y: 0, width: 640, height: 480))
        //                gc.fill(p, with: .color(.red))
        //                gc.draw(Text("Hello, World"), in: CGRect(x: 0, y: 0, width: 640, height: 480))
        //            }
        //            .resizable()
        //            .aspectRatio(contentMode: .fit)
    }
}

//#Preview {
//    AlmondBreadView()
//}
