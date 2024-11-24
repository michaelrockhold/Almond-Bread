//
//  ImageInfo+initializers.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import Foundation
import CoreData

extension ImageInfo {

    convenience init(context: NSManagedObjectContext, 
                     x: Double,
                     y: Double,
                     pixelWidth: Double,
                     width: Int,
                     height: Int,
                     colorScheme: Plotter.Scheme) {
        
        self.init(context: context)

        self.positionX = x
        self.positionY = y
        self.imageWidth = Int32(width)
        self.imageHeight = Int32(height)
        self.pixelWidth = pixelWidth
        self.colorScheme = Int16(colorScheme.rawValue)
    }

}