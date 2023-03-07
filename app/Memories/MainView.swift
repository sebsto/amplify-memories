//
//  MainView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import SwiftUI

struct MainView: View {
    
    @State public var memories: [Memory]
    @State private var tabSelected = 0
    
    var body: some View {
        TabView(selection: $tabSelected) {
            TodayView(memories: memories)
                .tabItem {
                    Label("Today", systemImage:"list.bullet")
                }
                .tag(0)
            AddMemoryView()
                .tabItem {
                    Label("Add", systemImage:"plus.square")
                }
                .tag(1)
            MapView(memories: memories)
                .tabItem {
                    Label("Map", systemImage:"map")
                }
                .tag(2)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let memories = Memory.mock
        MainView(memories: memories)
    }
}
