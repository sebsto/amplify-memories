//
//  MemoryDetailView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import SwiftUI
import CoreLocation
import MapKit

struct MemoryDetailView: View {
    
    @EnvironmentObject private var model: ViewModel
    @State var memory : Memory
    @State var region : MKCoordinateRegion
    
    init(memory: Memory) {
        
        _memory = State(initialValue: memory)
        
        var coordinate: CLLocationCoordinate2D = LocationManager.defaultLocation
        if let mc = memory.coordinates {
            coordinate = CLLocationCoordinate2D(latitude: mc.latitude,
                                                    longitude: mc.longitude)
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        _region = State(initialValue: MKCoordinateRegion(center: coordinate,
                                                             span: span))
    }
    
    var body: some View {
        
        ScrollView {
            VStack {
                Group {
                    Text(DateFormatter.localizedString(from: memory.moment.toDate()!,
                                                       dateStyle: .long,
                                                       timeStyle: .none))
                    .font(.title)
                    .bold()
                    
                    Text("\(memory.yearsAgo()) today")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                MemoryCondensedView(memory: memory)
                
                Text(memory.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding([.bottom])
                
                if memory.coordinates != nil {
                    Map(coordinateRegion: $region, annotationItems: [memory]) { memory in
                        MapMarker(coordinate: memory.locationCoordinate!)
                    }
                    .frame(height: 400)
                    .padding(.top)
                }
                
            } // Vstack
        } // ScrollView
    }
}

struct MemoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let memory = Memory.mock[0]
        MemoryDetailView(memory: memory)
    }
}
