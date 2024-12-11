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
            Calculator.Settings(width: Int(imageInfo.imageWidth),
                                height: Int(imageInfo.imageHeight),
                                centerX: imageInfo.positionX,
                                centerY: imageInfo.positionY,
                                pixelSize: imageInfo.pixelWidth,
                                maxIter: Int(imageInfo.maxIterations))
        }
        set {
            imageInfo.imageWidth = Int32(newValue.width)
            imageInfo.imageHeight = Int32(newValue.height)
            imageInfo.positionX = newValue.x
            imageInfo.positionY = newValue.y
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


    func updateCountData(settings: Calculator.Settings,
                         _ progressHandler: @escaping (Int)->Void,
                         onComplete: @escaping (Data, Calculator.Settings)->Void) async {

            // start calculating
            let total = imageInfo.expectedSize
            await self.calculator.calculate(settings: settings) { p in
                progressHandler(p)

            } onComplete: { (calculatedPoints, settings) in
                calculatedPoints.withUnsafeBufferPointer { bp in
                    onComplete(Data(buffer: bp), settings)
                }
            }
    }

    func updateImageData(settings: Renderer.Settings,
                         countData: Data,
                         _ progressHandler: @escaping (Int)->Void,
                         onComplete: @escaping (Data, Renderer.Settings)->Void) async {

        progressHandler(0)
        var pointCounts = Array<Calculator.PointResult>(repeating: Calculator.PointResult(),
                                                        count: countData.count / MemoryLayout<Calculator.PointResult>.stride)
        _ = pointCounts.withUnsafeMutableBytes { countData.copyBytes(to: $0) }

        let intPixels = await Renderer()
            .plotImage(settings: settings, counts: pointCounts, progressHandler: progressHandler)

        let idata = intPixels.withUnsafeBufferPointer { (b: UnsafeBufferPointer<IntPixel>) in
           return Data(buffer: b)
        }

        onComplete(idata, settings)
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

        let newCalculatorSettings = Calculator.Settings(width: settings.width,
                                                        height: settings.height,
                                                        centerX: settings.x,
                                                        centerY: settings.y,
                                                        pixelSize: settings.pixelWidth,
                                                        maxIter: settings.maxIterations)
        let newRendererSettings = Renderer.Settings(maxIterations: settings.maxIterations,
                                                    scheme: settings.colorScheme)

        if changes.contains(.cosmetic) {
            imageInfo.name = settings.name
        }

        do {
            if changes.contains(.dimensional) || self.imageInfo.countData == nil {
                reportRendering(progress: 0)
                await self.updateCountData(settings: newCalculatorSettings) { progress in
                    reportCalculation(progress: progress)
                } onComplete: { (data, settings) in
                    self.imageInfo.countData = data
                    self.calculatorSettings = settings
                    reportCalculationDone()
                }
            } else {
                reportCalculationDone()
            }

            if changes.contains(.rendering) || changes.contains(.dimensional) || self.imageInfo.imageData == nil {

                await self.updateImageData(settings: newRendererSettings,
                                           countData: self.imageInfo.countData!
                ) { progress in
                    reportRendering(progress: progress)

                } onComplete: { (data, settings) in
                    self.rendererSettings = settings
                    self.imageInfo.imageData = data
                    reportRenderingDone()
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
