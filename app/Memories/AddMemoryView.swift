//
//  AddMemoryView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 08/03/2023.
//

import SwiftUI
import MapKit

struct AddMemoryView: View {
    
    @EnvironmentObject var cameraModel: CameraViewModel // to access the CameraView state
    @EnvironmentObject var mainModel: ViewModel // to access backend functions
    
    @ObservedObject var locationManager = LocationManager()

    // data
    var image: UIImage? = nil
    var previewImage: Image? = nil // for preview only
    
    @State var description : String = ""
    
    var body: some View {
        VStack(spacing: 0.0) {
            
            if let i = image {
                Image(uiImage: i)
                    .resizable()
                    .scaledToFit()
            } else if let p = previewImage { // for preview only
                p
                    .resizable()
                    .foregroundColor(.pink)
                    .scaledToFit()
            }
            TextField("description",
                      text: $description,
                      prompt: Text("Write a note about this moment"))
            .frame(minHeight: 100, alignment: .top)
            //                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            //                .overlay(Rectangle().stroke(lineWidth: 1.0))
            .padding()
            
            // workaround to SwiftUI warning from
            // Xcode 14: Publishing changes from within view updates
            // https://developer.apple.com/forums/thread/711899?answerId=732977022#732977022
            
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
                userTrackingMode: nil)
            
            .padding(.bottom)
            .onAppear {
                locationManager.startUpdatingLocation()
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
            
            buttons()
        }
    }
    
    func buttons() -> some View {
        HStack {
            Button(action: {
                if let image = self.image {
                    Task {
                        self.cameraModel.state = .uploading

                        let coordinates: Coordinates? = self.locationManager.location?.coordinates()
                        
                        // create the memory. this will switch the view and refresh today's view
                        await self.mainModel.createMemory(
                                                      description: self.description,
                                                      image: image,
                                                      coordinates: coordinates)
                        

                    }
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.subheadline)
                    Text("Record")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }
                .padding()
                .foregroundColor(.white)
                .background(.tint)
                .cornerRadius(20)
            }
            Button(action: {
                self.cameraModel.state = .loadingPhoto
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.subheadline)
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }
                .padding()
                .foregroundColor(.white)
                .background(.red)
                .cornerRadius(20)
            }
        }
    }
}

struct AddMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        let image = Image(systemName: "heart")
        AddMemoryView(previewImage: image)
    }
}
