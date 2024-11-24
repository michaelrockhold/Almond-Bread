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
