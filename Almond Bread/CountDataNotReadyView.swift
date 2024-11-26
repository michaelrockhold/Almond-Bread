//
//  CountDataNotReadyView.swift
//  Almond Bread
//
//  Created by Michael Rockhold on 11/22/24.
//

import SwiftUI

struct CountDataNotReadyView: View {
    @State public var imageInfoViewModel: ImageInfoViewModel

    var body: some View {
        Text("COUNT NOT DATA READY, IMAGE DATA NOT READY")
            .padding(20)
    }


    func didDismiss() {
        // Handle the dismissing action.
    }
}

//#Preview {
//    CountDataNotReadyView(msg: "PREVIEW")
//}
