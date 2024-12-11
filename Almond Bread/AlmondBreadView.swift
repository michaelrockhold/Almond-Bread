//
//  AlmondBreadView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/17/24.
//

import SwiftUI

struct AlmondBreadView: View {

    @State private var isShowingSheet = false
    @StateObject var imageInfoViewModel: ImageInfoViewModel

    init(imageInfo: ImageInfo) {
        self._imageInfoViewModel = StateObject<ImageInfoViewModel>(wrappedValue: ImageInfoViewModel(imageInfo: imageInfo))
    }

    var body: some View {

        ZStack {
            if imageInfoViewModel.countGenerationProgress >= 1.0 && imageInfoViewModel.renderingProgress >= 1.0 {
                
                ImageDataReadyView(imageInfoViewModel: imageInfoViewModel)
                
            } else {

                ImageDataInProgressView(imageInfoViewModel: imageInfoViewModel)

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
            AdjustSettingsView(imageInfoViewModel: imageInfoViewModel)
        }
//        .onAppear() {
//            isShowingSheet = true
//        }
//        .task {
//            let countDataCancellable = imageInfoViewModel.imageInfo.publisher(for: \ImageInfo.countData)
//                .sink() {
//                    print ("ImageInfo.countData now: \($0)")
//                    imageInfoViewModel.update()
//            }
//
//
//            await Task.yield()
//
//            while true {
//                if Task.isCancelled {
//                    print("CANCELLED")
//                    break
//                }
//                try? await Task.sleep(nanoseconds: 5_000_000_000)
//            }
//        }



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
