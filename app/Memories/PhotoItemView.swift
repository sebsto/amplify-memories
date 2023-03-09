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

    @State private var tap = false

    var body: some View {
        
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
//                    .scaleEffect(tap ? 1.2 : 1)
//                    .animation(.spring(response: 0.4, dampingFraction: 0.6),value: UUID())
//                    .onTapGesture {
//                        tap.toggle()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                            tap = false
//                        }
//                    }

            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .task {
            guard image == nil, let cache = cache else { return }
            self.image = await Image(uiImage: asset.uiImage(in: cache, targetSize: imageSize))
        }
    }
}
