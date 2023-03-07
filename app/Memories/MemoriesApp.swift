//
//  MemoriesApp.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 23/02/2023.
//

import SwiftUI

// this is use by the logger in all classes
let PACKAGE_NAME : String = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "MemoriesApp"

@main
struct MemoriesApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(ContentView.ViewModel())
//            TEST()
        }
    }
}
