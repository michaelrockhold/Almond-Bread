//
//  AdjustSettingsView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import SwiftUI

struct AdjustSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var doSave: ()->Void

    @State private var title = ""
    @State private var author = ""
    @State private var rating = 3
    @State private var genre = "Fantasy"
    @State private var review = ""
    let genres = ["Fantasy", "Horror", "Kids", "Mystery", "Poetry", "Romance", "Thriller"]

    var body: some View {
        Form {
            Section {
                TextField("Name of book", text: $title)
                TextField("Author's name", text: $author)

                Picker("Genre", selection: $genre) {
                    ForEach(genres, id: \.self) {
                        Text($0)
                    }
                }
            }

            Section("Write a review") {
                TextEditor(text: $review)

                Picker("Rating", selection: $rating) {
                    ForEach(0..<6) {
                        Text(String($0))
                    }
                }
            }

            Section {
                Button("Save", role: .destructive) {
                    doSave()
                    dismiss()
                }
            }
        }
        .navigationTitle("Adjust Parameters")
        .padding(20)
    }
}

//#Preview {
//    AdjustSettingsView()
//}