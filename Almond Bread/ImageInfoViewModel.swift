//
//  ImageInfoViewModel.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/25/24.
//

import Foundation
import CoreGraphics

class ImageInfoViewModel: ObservableObject {

    let imageInfo: ImageInfo

    @Published var countGenerationProgress: Double
    @Published var countDataReady: Bool
    @Published var imageGenerationProgress: Double
    @Published var imageDataReady: Bool

    init(imageInfo: ImageInfo) {
        self.imageInfo = imageInfo
        self.countGenerationProgress = 0.0
        self.countDataReady = false
        self.imageGenerationProgress = 0.0
        self.imageDataReady = false

        let expectedDataSize = Int(imageInfo.imageWidth * imageInfo.imageHeight) * MemoryLayout<Calculator.PointResult>.size
        if let countData = imageInfo.countData {
            if countData.count == expectedDataSize {
                countGenerationProgress = 1.0
                countDataReady = true
            } else if countData.count < expectedDataSize {
                countGenerationProgress = Double(countData.count) / Double(expectedDataSize)
                countDataReady = false
            } else { // error
                countGenerationProgress = 0.0
                countDataReady = false
                imageInfo.countData = nil
            }
        } else {
            countGenerationProgress = 0.0
            countDataReady = false
        }

        if countDataReady {
            Task.detached { [self] in
                self.updateImageData(calculator: makeCalculator(), countData: imageInfo.countData!)
            }
        } else {
            Task.detached {
                await self.updateCountData()
            }
        }
    }

    func makeCalculator() -> Calculator {
        return Calculator(width: Int(imageInfo.imageWidth),
                          height: Int(imageInfo.imageHeight),
                          centerX: imageInfo.positionX,
                          centerY: imageInfo.positionY,
                          pixelSize: imageInfo.pixelWidth,
                          maxIter: Int(imageInfo.maxIterations),
                          viewModel: self)
    }

    func updateCountData() async {
        let c = makeCalculator()

        var pointCounts = [Calculator.PointResult]()
        await c.calculate(counts: &pointCounts)

        DispatchQueue.main.async { [self, pointCounts] in
            imageInfo.countData = pointCounts.withUnsafeBufferPointer { buffer in
                return Data(buffer: buffer)
            }
            do {
                try imageInfo.managedObjectContext?.save()
                countGenerationProgress = 1.0
                countDataReady = true
                self.updateImageData(calculator: c, pointCounts: pointCounts)
            } catch {
                fatalError()
            }
        }

    }

    func updateImageData(calculator: Calculator, countData: Data) {
        var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                        count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
        _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }

        updateImageData(calculator: calculator, pointCounts: pointCounts)
    }

    func updateImageData(calculator: Calculator, pointCounts: [Calculator.PointResult]) {

        let intPixels = Renderer(calculator: calculator, scheme: .classic)
            .plotImage(counts: pointCounts).map { IntPixel(doublePixel: $0) }

        DispatchQueue.main.async { [self, intPixels] in
            intPixels.withUnsafeBufferPointer { (b: UnsafeBufferPointer<IntPixel>) in
                imageInfo.imageData = Data(buffer: b)
                try? imageInfo.managedObjectContext?.save()
            }
            imageGenerationProgress = 1.0
            imageDataReady = true
        }
    }

}
