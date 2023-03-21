//
//  MapView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 02/03/2023.
//

import SwiftUI
import MapKit
import CoreLocation
import Logging

/*
 
 https://www.donnywals.com/xcode-14-publishing-changes-from-within-view-updates-is-not-allowed-this-will-cause-undefined-behavior/
 
 https://www.youtube.com/watch?v=3a7tuhVpoTQ
 
 */
struct MapView: View {
    
    let memories: [Memory]
    @ObservedObject var locationManager = LocationManager()

    init(memories: [Memory]) {
        // only show memories that have a coordinate
        self.memories = memories.filter { return $0.coordinates != nil }
    }
    
    // workaround to SwiftUI warning from
    // Xcode 14: Publishing changes from within view updates
    // https://developer.apple.com/forums/thread/711899?answerId=732977022#732977022
    
    var body: some View {

        NavigationStack {
            Map(coordinateRegion: .init(get: {
                locationManager.region
            }, set: { region in
                DispatchQueue.main.async {
                    locationManager.region = region
                }
            }),
//            Map(coordinateRegion: $locationManager.region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: nil,
                annotationItems: memories)
            { memory in
//                MapMarker(coordinate: memory.locationCoordinate)
//                    Text("Hello")

                MapAnnotation(coordinate: memory.locationCoordinate!) {
                    MapMarkerPhotoView(memory: memory)
                }
            }
            .onAppear {
                locationManager.startUpdatingLocation()
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
    }
}

struct MapMarkerPhotoView: View {

    @EnvironmentObject private var model: ViewModel

    var memory: Memory
    @State var imageURL: URL?

    var body: some View {
        NavigationLink(destination: MemoryDetailView(memory: memory)){
            VStack(spacing: 0) {
                AsyncImage(url: self.imageURL) { image in
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: 4))

                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.bottom)
                }

                Text(memory.yearsAgo())
                    .padding(5)
                    .font(.subheadline)
                    .background(.white.opacity(0.5), in: Capsule())
            }
            .onAppear {
                Task {
                    self.imageURL = await model.imageURL(for: memory)
                }
            }
        }

    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let memories = Memory.mock
        
        MapView(memories: memories).environmentObject(ViewModel())
//        MapMarkerPhotoView(memory: memories[1])
    }
}
