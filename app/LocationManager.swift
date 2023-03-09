//
//  LocationManager.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 08/03/2023.
//

import Foundation
import CoreLocation
import MapKit
import Logging

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let defaultLocation = CLLocationCoordinate2D(latitude: 50.6292,
                                                        longitude: 3.0573)
    
    private var logger = Logger(label: "\(PACKAGE_NAME).LocationManager")
    
    private var manager: CLLocationManager? = nil
    
    @Published var location: CLLocationCoordinate2D?
    @Published var region : MKCoordinateRegion = .init(
        center: LocationManager.defaultLocation,
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    public static var shared: LocationManager = LocationManager()
    private override init() {
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
