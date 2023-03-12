/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI
import Photos

struct PhotoItemView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    var imageSize: CGSize
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?

    var body: some View {
        
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .onAppear {
            Task {
                guard image == nil, let cache = cache else { return }
//                self.image = await Image(uiImage: asset.uiImage(in: cache, targetSize: imageSize))
                self.imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
                    Task {
                        if let result = result {
                            self.image = result.image
                        }
                    }
                }
            }
        }
    }
}

//struct PhotoItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotoItemView()
//    }
//}
