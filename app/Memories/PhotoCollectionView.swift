/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI
import os.log

struct PhotoCollectionView: View {
    
    @EnvironmentObject var cameraModel: CameraViewModel
    @ObservedObject var photoCollection : PhotoCollection
    
    @Environment(\.displayScale) private var displayScale
    
    private let itemSpacing = 2.0
    private let column = 4.0
    
    private func itemSize(containerWidth: CGFloat) -> CGSize {
        let newImageSize = (containerWidth / column) - itemSpacing
        return CGSize(width: newImageSize, height: newImageSize)
    }
    private func imageSize(containerWidth: CGFloat) -> CGSize {
        // squared image
        return CGSize(width: itemSize(containerWidth: containerWidth).width * min(displayScale, 2),
                      height: itemSize(containerWidth: containerWidth).height * min(displayScale, 2))
    }
    
    private func columns(containerWidth: CGFloat) -> [GridItem] {
        let newImageSize = itemSize(containerWidth: containerWidth)
        return [GridItem(.adaptive(minimum: newImageSize.width), spacing: itemSpacing)]
    }
    
    var body: some View {
        GeometryReader { reader in
            let actualWidth = reader.size.width
            VStack {
//                let firstAsset = photoCollection.photoAssets[0]
//                if let phAsset = firstAsset.phAsset {
//                    let pictureSize = CGSize(width: phAsset.pixelWidth,
//                                             height: phAsset.pixelHeight)
//                    
//                    PhotoItemView(asset: firstAsset,
//                                  cache: photoCollection.cache,
//                                  imageSize: pictureSize)
//                }
                
                ScrollView {
                    LazyVGrid(columns: columns(containerWidth: actualWidth),
                              spacing: itemSpacing) {
                        
                        ForEach(photoCollection.photoAssets) { asset in
                            photoItemView(asset: asset, containerWidth: actualWidth)
                        }
                    }
                }
            }
        }
    }
    
    private func photoItemView(asset: PhotoAsset, containerWidth: CGFloat) -> some View {
        PhotoItemView(asset: asset,
                      cache: photoCollection.cache,
                      imageSize: imageSize(containerWidth: containerWidth))
        
        .frame(width: itemSize(containerWidth: containerWidth).width,
               height: itemSize(containerWidth: containerWidth).height)
        .clipped()
        .onAppear {
            Task {
                await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize(containerWidth: containerWidth))
            }
        }
        .onDisappear {
            Task {
                await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize(containerWidth: containerWidth))
            }
        }
        .onTapGesture {
            Task {
                if let phAsset = asset.phAsset {
                    let pictureSize = CGSize(width: phAsset.pixelWidth,
                                             height: phAsset.pixelHeight)
                    let selectedImage = await asset.uiImage(in: photoCollection.cache,
                                                            targetSize: pictureSize)
                    self.cameraModel.selectedImage(image: selectedImage)
                } else {
                    fatalError("no phAsset in asset. I want to be informed if this happens")
                }
            }
        }
    }
}

struct PhotoCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        let pc = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
        PhotoCollectionView(photoCollection: pc).environmentObject(CameraViewModel())
    }
}
