/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI

struct CameraView: View {
    @EnvironmentObject var mainModel: ViewModel // to access backend functions
    @EnvironmentObject var cameraModel: CameraViewModel
    
    var body: some View {
        
        switch cameraModel.photoState {
        case .noPhotoSelected:
            VStack(alignment: .trailing, spacing: 0.0) {
                ViewfinderView(image:  $cameraModel.viewfinderImage )
                    .background(.black)
                buttonsView()
                    .background(.black.opacity(0.75))
                if cameraModel.isPhotosLoaded {
                    PhotoCollectionView(photoCollection: cameraModel.photoCollection)
                }
            }
            .task {
                await cameraModel.camera.start()
                await cameraModel.loadPhotos()
            }
            
        case .photoSelected(let image):
            AddMemoryView(image: image)
            
        case .uploading:
            ProgressView {
                Text("Uploading image and creating your memory")
            }
        }
    }
        
        private func buttonsView() -> some View {
            HStack(spacing: 60) {
                
                Spacer()
                
                Button {
                    cameraModel.camera.takePhoto()
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
