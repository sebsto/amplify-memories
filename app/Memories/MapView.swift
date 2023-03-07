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
    @ObservedObject var locationManager: LocationManager = LocationManager()

    init(memories: [Memory]) {
        
        self.memories = memories
    }
    
    // workwround to SwiftUI warning from
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
                MapAnnotation(coordinate: memory.locationCoordinate) {
//                    Text("Hello")
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
            .ignoresSafeArea()
//            .edgesIgnoringSafeArea(.top)
        }
    }
}

struct MapMarkerPhotoView: View {

    var memory: Memory
    var body: some View {
        NavigationLink(destination: MemoryDetailView(memory: memory)){
            VStack(spacing: 0) {
                AsyncImage(url: memory.imageURL) { image in
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
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
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let memories = Memory.mock
        
        MapView(memories: memories)
//        MapMarkerPhotoView(memory: memories[1])
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let defaultLocation = CLLocationCoordinate2D(latitude: 50.6292,
                                                        longitude: 3.0573)
    
    private var logger = Logger(label: "\(PACKAGE_NAME).LocationManager")
    
    private var manager: CLLocationManager? = nil
    
    @Published var location: CLLocationCoordinate2D?
    @Published var region : MKCoordinateRegion = .init(
        center: LocationManager.defaultLocation,
        span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
    )
    
    override init() {
        super.init()
        
#if DEBUG
        self.logger.logLevel = .debug
#endif
    }
    
    func startUpdatingLocation() {
        if manager == nil {
            manager = CLLocationManager()
            manager!.delegate = self
            manager!.desiredAccuracy = kCLLocationAccuracyBest
            manager!.requestWhenInUseAuthorization()
        }
    }
    
    func stopUpdatingLocation() {
        manager?.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("[didUpdateLocations] \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        logger.debug("[didUpdateLocations] received location update: \(locations)")
        if let l = locations.last {
            location = l.coordinate
            
            region = MKCoordinateRegion(center: l.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.3,
                                                               longitudeDelta: 0.3))
        }
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        if manager.authorizationStatus == .authorizedWhenInUse{
            logger.debug("[didUpdateLocations] Authorized")
            manager.startUpdatingLocation()
        } else {
            logger.debug("[didUpdateLocations] Not authorized")
            manager.requestWhenInUseAuthorization()
        }
    }
    
}

