//
//  AlmondBreadView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/17/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct AlmondBreadView: View {
    
    @State private var isShowingSheet = false
    @State private var isShowingExporter = false
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
            ToolbarItem(placement: .automatic) {
                Button("Export Image", systemImage: "square.and.arrow.up") {
                    isShowingExporter = true
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            AdjustSettingsView(imageInfoViewModel: imageInfoViewModel)
        }
        .fileExporter(isPresented: $isShowingExporter, document: ImageInfoFileDocument(imageInfo: self.imageInfoViewModel), contentType: .jpeg) { result in
            
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

//        .onAppear() {
//            isShowingSheet = true
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


struct ImageInfoFileDocument: FileDocument {
    enum ImageInfoFileDocumentError: Error {
        case notReady
        case cannotCreateData
    }
    
    static var readableContentTypes = [UTType.jpeg]
        
    let imageInfo: ImageInfoViewModel
    
    init(configuration: FileDocument.ReadConfiguration) throws {
        // this is never called, because we don't read these in
        fatalError("INTERNAL ERROR")
    }

    init(imageInfo: ImageInfoViewModel) {
        self.imageInfo = imageInfo
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // this is the whole point of FileDocument, for our purposes
        
        guard let cgImage = imageInfo.renderedImage else {
            throw ImageInfoFileDocumentError.notReady
        }
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: cgImage)
        guard let data = cicontext.jpegRepresentation(of: ciimage, colorSpace: ciimage.colorSpace!) else {
            throw ImageInfoFileDocumentError.cannotCreateData
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
