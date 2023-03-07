//
//  AddMemoryView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import SwiftUI

struct AddMemoryView: View {
    
    @StateObject private var model = AddMemoryViewModel()

    var body: some View {
        CameraView()
    }
}

struct AddMemoryView_Previews: PreviewProvider {

    static var previews: some View {
        let model = ContentView.ViewModel()
        AddMemoryView().environmentObject(model)
    }
}
