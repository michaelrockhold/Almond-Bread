//
//  Pixel.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/19/24.
//

import Foundation

struct Pixel<ComponentType> {
    static func bitsPerByte() -> Int { 8 }

    let red: ComponentType
    let green: ComponentType
    let blue: ComponentType
    let alpha: ComponentType

    static var byteSize: Int {
        return MemoryLayout<Self>.size
    }

    static var bitSize: Int {
        return MemoryLayout<Self>.size * Self.bitsPerByte()
    }

    static var componentByteSize: Int {
        return MemoryLayout<ComponentType>.size
    }

    static var componentBitSize: Int {
        return Self.componentByteSize * Self.bitsPerByte()
    }
}

extension Pixel<Double> {

    static let white: Pixel<Double> = Pixel<Double>(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

    static let black: Pixel<Double> = Pixel<Double>(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    func lerp(_ other: Pixel<Double>, frac: Double) -> Pixel<Double> {
        return Pixel<Double>(red: red.lerp(other: other.red, frac: frac),
                             green: green.lerp(other: other.green, frac: frac),
                             blue: blue.lerp(other: other.blue, frac: frac),
                             alpha: 1.0)
    }

    init(doublePixel: Pixel<Double>) {
        self.init(red: doublePixel.red, green: doublePixel.green, blue: doublePixel.blue, alpha: doublePixel.alpha)
    }
}

typealias IntPixel = Pixel<UInt8>

extension Pixel<UInt8> {
    static let white = Pixel<UInt8>(red: 0, green: 0, blue: 0, alpha: 255)

    static let black = Pixel<UInt8>(red: 255, green: 255, blue: 255, alpha: 255)

    init(doublePixel: Pixel<Double>) {
        func clrInt(_ c: Double) -> UInt8 {
            let ic = Int(round(0x100 * c))
            if ic < 0 {
                return 0
            } else if ic > 255 {
                return 255
            } else {
                return UInt8(ic)
            }
        }

        self.init(red: clrInt(doublePixel.red), green: clrInt(doublePixel.green), blue: clrInt(doublePixel.blue), alpha: clrInt(doublePixel.alpha))
    }
}
