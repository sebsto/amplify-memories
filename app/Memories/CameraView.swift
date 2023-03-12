//
//  CameraView.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 11/03/2023.
//

import SwiftUI

struct CameraView: View {
    
    @EnvironmentObject var cameraModel: CameraViewModel

    var body: some View {
        
        ZStack {
            ViewfinderView(image:  $cameraModel.viewfinderImage )
                .background(.black)
            VStack {
                Spacer()
                buttonsView()
                    .background(.black.opacity(0.75))
            }
        }
        .task {
            await cameraModel.camera.start()
        }
    }
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            
            Spacer()
            
            Button {
                cameraModel.takePhoto()                
            } label: {
                Label {
                    Text("Take Photo")
                } icon: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 62, height: 62)
                        Circle()
                            .fill(.white)
                            .frame(width: 50, height: 50)
                    }
                }
            }
            
            Button {
                cameraModel.camera.switchCaptureDevice()
            } label: {
                Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding()
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView().environmentObject(CameraViewModel())
    }
}
