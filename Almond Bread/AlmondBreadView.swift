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
        guard let data = imageInfo.jpegData else {
            throw ImageInfoFileDocumentError.cannotCreateData
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
