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
    @Published var countDataReady: Bool
    @Published var imageGenerationProgress: Double
    @Published var renderedImage: CGImage?

    private var countDataCancellable: AnyCancellable!
    private var imageDataCancellable: AnyCancellable!

    init(imageInfo: ImageInfo) {
        self.imageInfo = imageInfo
        self.countGenerationProgress = 0.0
        self.countDataReady = false
        self.imageGenerationProgress = 0.0

        self.countDataCancellable = imageInfo.publisher(for: \.countData)
            .sink() { [weak self] in
                guard let this = self else { return }
                print ("ImageInfo.countData now: \($0)")
                if let data = this.imageInfo.countData {
                    Task.detached {
                        await this.updateImageData(maxIterations: Int(imageInfo.maxIterations), countData: data)
                    }
                } else {
                    imageInfo.imageData = nil
                }
        }

        self.imageDataCancellable = imageInfo.publisher(for: \.imageData)
            .sink() { [weak self] in
                print ("ImageInfo.imageData now: \($0)")
                guard let this = self else { return }

                Task.detached {
                    await this.updateCGImage(this.makeCGImage(from: imageInfo.imageData))
                }
            }
    }

    @MainActor
    private func updateImageInfoImageData(_ data: Data?) {
        imageInfo.imageData = data
    }

    @MainActor
    private func updateCGImage(_ image: CGImage?) {
        renderedImage = image
    }

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
            countDataReady = true
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
        await self.updateImageInfoImageData(idata)
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

        if changes.contains(.cosmetic) {
            imageInfo.name = settings.name
        }
        if changes.contains(.rendering) {
            imageInfo.scheme = settings.colorScheme
            imageInfo.imageData = nil
        }
        if changes.contains(.dimensional) {
            imageInfo.positionX = settings.x
            imageInfo.positionY = settings.y

            imageInfo.imageWidth = Int32(settings.width)
            imageInfo.imageHeight = Int32(settings.height)

            imageInfo.pixelWidth = settings.pixelWidth

            imageInfo.maxIterations = Int32(settings.maxIterations)

            imageInfo.countData = nil // force these to be updated
            imageInfo.imageData = nil
            countDataReady = false
        }

        saveImageInfo()
    }
}
