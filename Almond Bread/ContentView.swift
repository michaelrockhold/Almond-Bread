//
//  ContentView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/16/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ImageInfo.name, ascending: true)],
        animation: .default)
    private var imageInfos: FetchedResults<ImageInfo>

    var body: some View {
        NavigationView {
            List {
                ForEach(imageInfos) { imageInfo in
                    NavigationLink {
                        AlmondBreadView(imageInfo: imageInfo)
                    } label: {
                        Text(imageInfo.name ?? "Untitled")
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("New Image", systemImage: "plus")
                    }
                }
            }
            Text("Select a set of image parameters")
        }
    }

    private func addItem() {
        withAnimation {
            let _ = ImageInfo(context: viewContext,
                              x: -0.7412067031270126,
                              y: -0.1207678370473447,
                              pixelWidth: 1.0940668476076224e-11,
                              width: 800,
                              height: 600,
                              maxIterations: 1000,
                              colorScheme: .classic)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { imageInfos[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
