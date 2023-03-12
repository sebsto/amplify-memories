//
//  MainView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var model: ViewModel
            
    var body: some View {
        TabView(selection: $model.tabSelected) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage:"list.bullet")
                }
                .tag(0)
            PhotoSelectionView()
                .environmentObject(CameraViewModel())
                .tabItem {
                    Label("Add", systemImage:"plus.square")
                }
                .tag(1)
            MapView(memories: model.memories)
                .tabItem {
                    Label("Map", systemImage:"map")
                }
                .tag(2)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let model = ViewModel(memories: Memory.mock)
        MainView().environmentObject(model)
    }
}
