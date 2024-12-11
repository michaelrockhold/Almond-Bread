//
//  AdjustSettingsView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import SwiftUI

struct AdjustSettingsView: View {

    public struct SettingsViewModel {
        var name: String
        var colorScheme: Renderer.Scheme
        var x: Double
        var y: Double
        var pixelWidth: Double
        var width: Int
        var height: Int
        var maxIterations: Int

        init() {
            self.name = ""
            self.colorScheme = .classic
            self.x = 0.0
            self.y = 0.0
            self.pixelWidth = 0.0
            self.width = 0
            self.height = 0
            self.maxIterations = 0
        }

        init(imageInfo: ImageInfo) {
            self.name = imageInfo.name ?? ""
            self.colorScheme = imageInfo.scheme
            self.x = imageInfo.positionX
            self.y = imageInfo.positionY
            self.pixelWidth = imageInfo.pixelWidth
            self.width = Int(imageInfo.imageWidth)
            self.height = Int(imageInfo.imageHeight)
            self.maxIterations = Int(imageInfo.maxIterations)
        }

        func compare(to other: SettingsViewModel) -> SettingsChangeOptions {
            var changeOptions: SettingsChangeOptions = []

            if self.name != other.name {
                changeOptions.insert(.cosmetic)
            }
            if self.colorScheme != other.colorScheme {
                changeOptions.insert(.rendering)
            }
            if self.height != other.height
                || self.width != other.width
                || self.x != other.x
                || self.y != other.y
                || self.pixelWidth != other.pixelWidth
                || self.maxIterations != other.maxIterations {
                changeOptions.insert(.dimensional)
            }

            return changeOptions
        }
    }

    struct SettingsChangeOptions: OptionSet {
        let rawValue: Int

        static let cosmetic      = SettingsChangeOptions(rawValue: 1 << 0)
        static let rendering     = SettingsChangeOptions(rawValue: 1 << 1)
        static let dimensional   = SettingsChangeOptions(rawValue: 1 << 2)
    }

    @Environment(\.dismiss) private var dismiss

    let imageInfoViewModel: ImageInfoViewModel
    @State private var settings: SettingsViewModel = SettingsViewModel()
    @State private var originalSettings: SettingsViewModel = SettingsViewModel()

    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    var body: some View {
        Form {
            Section {
                TextField("Name of image", text: $settings.name)
                TextField("X", value: $settings.x, format: .number.notation(.scientific).precision(.significantDigits(16)))
                TextField("Y", value: $settings.y, format: .number.notation(.scientific).precision(.significantDigits(16)))
                TextField("Pixel Width", value: $settings.pixelWidth, format: .number.notation(.scientific).precision(.significantDigits(16)))

                TextField("Image Width", value: $settings.width, format: .number)
                TextField("Image Height", value: $settings.height, format: .number)
                TextField("Maximum Iterations", value: $settings.maxIterations, format: .number)
                Picker("Color Scheme", selection: $settings.colorScheme) {
                    ForEach(Renderer.Scheme.allCases) { option in
                        Text(String(describing: option))
                    }
                }
                #if os(macOS)
                .pickerStyle(.automatic)
                #else
                .pickerStyle(.wheel)
                #endif
            }


            Section {
                HStack {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }

                    Button("Save", role: .destructive) {
                        let changes = settings.compare(to: originalSettings)
                        Task {
                            await imageInfoViewModel.apply(settings: settings,
                                                     changes: changes)
                        }
                        dismiss()
                    }
                    .disabled(settings.compare(to: originalSettings).isEmpty)
                }
            }
        }
        .navigationTitle("Adjust Parameters")
        .padding(20)
        .onAppear {
            self.settings = SettingsViewModel(imageInfo: imageInfoViewModel.imageInfo)
            self.originalSettings = self.settings
        }
    }
}

//#Preview {
//    AdjustSettingsView()
//}
