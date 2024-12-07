//
//  ImageInfoViewModel.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/25/24.
//

import Foundation
import CoreGraphics
import Combine

class ImageInfoViewModel: ObservableObject {

    let imageInfo: ImageInfo

    @Published var countGenerationProgress: Double
    @Published var imageGenerationProgress: Double

    var renderedImage: CGImage?

    private var countDataCancellable: AnyCancellable!
    private var imageDataCancellable: AnyCancellable!
    private var renderSettingsCancellable: AnyCancellable!

    init(imageInfo: ImageInfo) {
        self.imageInfo = imageInfo
        self.countGenerationProgress = 0.0
        self.imageGenerationProgress = 0.0

        self.countDataCancellable = imageInfo.publisher(for: \.countData)
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] in
                guard let this = self else { return }
                print ("ImageInfo.countData now: \($0)")
                
                if let countData = this.imageInfo.countData {
                    // there is countData; it is either enough, in which case rendering may begin, or its not, in which case we finish calculation
                    if countData.count < this.imageInfo.expectedSize { // finish calculations
                        
                        Task.detached {
                            countGenerationProgress = 0.0
                            
                            var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                                            count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
                            _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }
                            self?.makeCalculator().calculate(counts: &pointCounts)
                            
                            pointCounts.withUnsafeBufferPointer { bp in
                                self?.imageInfo.countData = Data(buffer: bp)
                            }
                        }
                    } else { // proceed with image rendering
                        
                        Task.detached {
                            var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                                            count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
                            _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }
                            await updateImageData(maxIterations: Int(self!.imageInfo.maxIterations), pointCounts: pointCounts)
                        }
                    }
                    
                } else {
                    // countData is nil
                    countGenerationProgress = 0.0
                    self?.makeCalculator().calculate(counts: &<#T##[Calculator.PointResult]#>)
                }
            }
        
        self.renderSettingsCancellable = imageInfo.publisher(for: \.colorScheme)
            .receive(on: DispatchQueue.main)
            .sink() {_ in
                self.imageInfo.imageData = nil
                self.imageGenerationProgress = 0.0
                guard let data = self.imageInfo.countData else {
                    fatalError("NO COUNT DATA")
                }

                Task.detached {
                    await self.updateImageData(maxIterations: Int(imageInfo.maxIterations), countData: data)
                }
            }

        self.imageDataCancellable = imageInfo.publisher(for: \.imageData)
            .receive(on: DispatchQueue.main)
            .sink() { [weak self] in
                print ("ImageInfo.imageData now: \($0)")
                guard let self = self else { return }

                self.renderedImage = self.makeCGImage(from: imageInfo.imageData)
            }
    }
    
//    @MainActor
//    private func updateImageInfoImageData(_ data: Data?) {
//        imageInfo.imageData = data
//    }
    
    
    @MainActor
    private func updateImageInfoCountData(_ data: Data?) {
        imageInfo.countData = data
    }

    //    func update() {
    //        let expectedDataSize = Int(imageInfo.imageWidth * imageInfo.imageHeight) * MemoryLayout<Calculator.PointResult>.size
    //        if let countData = imageInfo.countData {
    //            if countData.count == expectedDataSize {
    //                countGenerationProgress = 1.0
    //                countDataReady = true
    //            } else if countData.count < expectedDataSize {
    //                countGenerationProgress = Double(countData.count) / Double(expectedDataSize)
    //                countDataReady = false
    //            } else { // error
    //                countGenerationProgress = 0.0
    //                countDataReady = false
    //                imageInfo.countData = nil
    //            }
    //        } else {
    //            countGenerationProgress = 0.0
    //            countDataReady = false
    //        }
    //
    //        if countDataReady {
    //            self.updateImageData(maxIterations: Int(imageInfo.maxIterations), countData: imageInfo.countData!)
    //        } else {
    //            self.updateCountData()
    //        }
    //    }

    func makeCalculator() -> Calculator {
        return Calculator(width: Int(imageInfo.imageWidth),
                          height: Int(imageInfo.imageHeight),
                          centerX: imageInfo.positionX,
                          centerY: imageInfo.positionY,
                          pixelSize: imageInfo.pixelWidth,
                          maxIter: Int(imageInfo.maxIterations),
                          viewModel: self)
    }

    func updateCountData() {
        var pointCounts = [Calculator.PointResult]()
        makeCalculator().calculate(counts: &pointCounts)

        let cdata = pointCounts.withUnsafeBufferPointer { buffer in
            return Data(buffer: buffer)
        }
        countGenerationProgress = 1.0
        Task.detached {  [cdata] in
            await self.updateImageInfoCountData(cdata)
        }
        do {
            try imageInfo.managedObjectContext?.save()
        } catch {
            fatalError()
        }
    }
    
    func updateImageData(maxIterations: Int, countData: Data) async {
        var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                        count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
        _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }
        
        await updateImageData(maxIterations: maxIterations, pointCounts: pointCounts)
    }
    
    func updateImageData(maxIterations: Int, pointCounts: [Calculator.PointResult]) async {

        let intPixels = Renderer(maxIterations: maxIterations, scheme: .classic)
            .plotImage(counts: pointCounts)

        var idata: Data? = nil
        intPixels.withUnsafeBufferPointer { (b: UnsafeBufferPointer<IntPixel>) in
            idata = Data(buffer: b)
        }

        imageInfo.imageData = idata
        try? imageInfo.managedObjectContext?.save()
        imageGenerationProgress = 1.0
    }

    private func makeCGImage(from imageData: Data?) -> CGImage? {
        guard let data = imageData else {
            return nil
        }

        guard let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }

        return CGImage(width: Int(imageInfo.imageWidth),
                       height: Int(imageInfo.imageHeight),
                       bitsPerComponent: IntPixel.componentBitSize,
                       bitsPerPixel: IntPixel.bitSize,
                       bytesPerRow: Int(imageInfo.imageWidth) * IntPixel.byteSize,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)

    }

    private func saveImageInfo() {
        do {
            try imageInfo.managedObjectContext?.save()
        } catch {
            // TODO: handle this less casually
            fatalError("ERROR saving imageInfo")
        }
    }

    func apply(settings: AdjustSettingsView.SettingsViewModel,
               changes: AdjustSettingsView.SettingsChangeOptions) {
        
        var resetCalculation = false
        var resetRendering = false

        if changes.contains(.cosmetic) {
            imageInfo.name = settings.name
        }
        
        switch (changes.contains(.dimensional), changes.contains(.rendering)) {
        case (true, true):
            imageInfo.imageData = nil
            imageGenerationProgress = 0.0
            imageInfo.countData = nil
            countGenerationProgress = 0.0
            
        case (true, false):
            imageInfo.imageData = nil
            imageGenerationProgress = 0.0
            imageInfo.countData = nil
            countGenerationProgress = 0.0

        case (false, true):
            imageInfo.imageData = nil
            imageGenerationProgress = 0.0
            
        case (false, false):
            break
        }

        saveImageInfo()
    }
}
