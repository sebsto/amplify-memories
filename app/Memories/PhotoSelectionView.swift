/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI

struct PhotoSelectionView: View {
    @EnvironmentObject var mainModel: ViewModel // to access backend functions
    @EnvironmentObject var cameraModel: CameraViewModel
    
    var body: some View {
        
        switch cameraModel.state {
            
        case .loadingPhoto:
            loadingView()
                .task {
                    await cameraModel.loadPhotos()
                }
            
        case .albumLoaded:
            PhotoCollectionView()
            
        case .capturePhoto:
            CameraView()

        case .photoSelected(let image):
            AddMemoryView(image: image)
            
        case .uploading:
            ProgressView {
                Text("Uploading image and creating your memory")
            }
        }
    }
     
    @ViewBuilder
    func loadingView() -> some View {
        VStack {
            ProgressView()
                .padding(.bottom)
            Text("Loading photo album")
        }
    }
}
