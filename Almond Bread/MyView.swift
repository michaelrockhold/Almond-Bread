//
//  MyView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import SwiftUI

#Preview {
    MyView()
}

struct MyView: View {
    @State private var isShowingSheet = false
    @State private var booksCount = 0


    var body: some View {
        Text("Count: \(booksCount)")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Adjust Parameters", systemImage: "gearshape") {
                        isShowingSheet.toggle()
                    }
                }
            }
            .sheet(isPresented: $isShowingSheet) {
                AdjustSettingsView {
                    booksCount += 1
                }
            }
    }


    func didDismiss() {
        // Handle the dismissing action.
    }
}
