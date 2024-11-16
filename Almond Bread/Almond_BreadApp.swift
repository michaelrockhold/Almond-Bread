//
//  Almond_BreadApp.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/16/24.
//

import SwiftUI

@main
struct Almond_BreadApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
