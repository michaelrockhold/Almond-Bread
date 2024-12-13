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
    @Published var renderingProgress: Double = 0.0
    @Published var renderedImage: CGImage? = nil

    private let calculator = Calculator()

    init(imageInfo: ImageInfo) {
        self.imageInfo = imageInfo
        countGenerationProgress = 0.0

        let settingsVM = AdjustSettingsView.SettingsViewModel(imageInfo: imageInfo)
        Task {
            await apply(settings: settingsVM, changes: [])
        }

    }

    var calculatorSettings: Calculator.Settings {
        get {
            Calculator.Settings(imageDimensions: Calculator.Settings.ImageDimensions(width: Int(imageInfo.imageWidth), height: Int(imageInfo.imageHeight)),
                                center: Calculator.Settings.Point(x: imageInfo.positionX, y: imageInfo.positionY),
                                maxIter: Int(imageInfo.maxIterations),
                                pixelSize: imageInfo.pixelWidth)
        }
        set {
            imageInfo.imageWidth = Int32(newValue.imageDimensions.width)
            imageInfo.imageHeight = Int32(newValue.imageDimensions.height)
            imageInfo.positionX = newValue.center.x
            imageInfo.positionY = newValue.center.y
            imageInfo.pixelWidth = newValue.pixelSize
            imageInfo.maxIterations = Int32(newValue.maxIter)
        }
    }

    var rendererSettings: Renderer.Settings {
        get {
            Renderer.Settings(maxIterations: Int(imageInfo.maxIterations),
                              scheme: imageInfo.scheme)
        }
        set {
            imageInfo.maxIterations = Int32(newValue.maxIterations)
            imageInfo.scheme = newValue.scheme
        }
    }

    func updateImageData(settings: Renderer.Settings,
                         countData: Data,
                         _ progressHandler: @escaping (Int)->Void) async -> Result<(Data, Renderer.Settings), Error> {

        progressHandler(0)
        var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                        count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
        _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }

        let rendering = await Renderer()
            .plotImage(settings: settings, counts: pointCounts, progressHandler: progressHandler)

        switch rendering {
        case .success(let pixels):
            let idata = pixels.withUnsafeBufferPointer { (b: UnsafeBufferPointer<IntPixel>) in
               return Data(buffer: b)
            }
            return .success((idata, settings))
            
        case .failure(let e):
            return .failure(e)
        }
    }

    func updateImage(data: Data, width: Int, height: Int, _ onComplete: @escaping (CGImage)->Void) async {

        let provider = CGDataProvider(data: data as CFData)!
        onComplete(CGImage(width: Int(width),
                           height: Int(height),
                           bitsPerComponent: IntPixel.componentBitSize,
                           bitsPerPixel: IntPixel.bitSize,
                           bytesPerRow: Int(width) * IntPixel.byteSize,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                           provider: provider,
                           decode: nil,
                           shouldInterpolate: false,
                           intent: .defaultIntent)!)
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
               changes: AdjustSettingsView.SettingsChangeOptions) async {

        func onMain(_ fn: @escaping ()->Void) { DispatchQueue.main.async { fn() } }

        func reportCalculation(progress: Int) {
            onMain { self.countGenerationProgress = Double(progress) / Double(settings.width * settings.height) }
        }
        func reportCalculationDone() {
            onMain { self.countGenerationProgress = 1.0 }
        }
        func reportRendering(progress: Int) {
            onMain { self.renderingProgress = Double(progress) / Double(settings.width * settings.height) }
        }
        func reportRenderingDone() {
            onMain { self.renderingProgress = 1.0 }
        }

        let newCalculatorSettings = Calculator.Settings(imageDimensions: Calculator.Settings.ImageDimensions(width: settings.width, height: settings.height),
                                                        center: Calculator.Settings.Point(x: settings.x, y: settings.y),
                                                        maxIter: settings.maxIterations,
                                                        pixelSize: settings.pixelWidth)
        let newRendererSettings = Renderer.Settings(maxIterations: settings.maxIterations,
                                                    scheme: settings.colorScheme)

        if changes.contains(.cosmetic) {
            imageInfo.name = settings.name
        }

        do {
            if changes.contains(.dimensional) || self.imageInfo.countData == nil {
                reportRendering(progress: 0)
                let calculation = await self.calculator.calculate(settings: newCalculatorSettings) { progress in
                    reportCalculation(progress: progress)
                }
                                
                switch calculation {
                case .success(let result):
                    
                    self.calculatorSettings = result.1
                    result.0.withUnsafeBufferPointer { bp in
                        self.imageInfo.countData = Data(buffer: bp)
                    }
                    reportCalculationDone()

                case .failure(let error):
                    // TODO: handle this unusual thing, or make Failure=Never
                    break
                }
            } else {
                reportCalculationDone()
            }

            if changes.contains(.rendering) || changes.contains(.dimensional) || self.imageInfo.imageData == nil {

                reportRendering(progress: 0)
                let imageRenderingResult = await self.updateImageData(settings: newRendererSettings,
                                                                      countData: self.imageInfo.countData!) {
                    reportRendering(progress: $0)
                }
                switch imageRenderingResult {
                case .success(let good):
                    self.rendererSettings = good.1
                    self.imageInfo.imageData = good.0
                    reportRenderingDone()
                    
                case .failure(let bad):
                    // TODO: handle this unusual thing, or make Failure=Never
                    break
                }
            } else {
                reportRenderingDone()
            }

            await self.updateImage(data: self.imageInfo.imageData!,
                                       width: Int(imageInfo.imageWidth),
                                       height: Int(imageInfo.imageHeight)) { img in
                onMain { self.renderedImage = img }
            }
        } catch {
            fatalError("TODO: handle this properly")
        }

        saveImageInfo()
    }
}
