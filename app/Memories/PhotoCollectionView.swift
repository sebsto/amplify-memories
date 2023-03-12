/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI
import Photos
import os.log

struct PhotoCollectionView: View {
    
    @EnvironmentObject var cameraModel: CameraViewModel
    
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
        let photoCollection = cameraModel.photoCollection
        
        GeometryReader { reader in
            let actualWidth = reader.frame(in: .local).size.width
            let actualHeight = reader.frame(in: .local).size.height

            VStack {
                
                if let image = cameraModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: actualHeight / 2.4)
                        .onTapGesture {
                            self.cameraModel.state = .photoSelected(image)
                        }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.accentColor)
                        .opacity(0.2)
                        .frame(height: actualHeight / 2.4)
                }

                HStack {
                    Button(action: {
                        
                        if let image = cameraModel.selectedImage {
                            self.cameraModel.state = .photoSelected(image)
                        }
                        
                    }) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height: 30)
                            .padding()
                    }
                    
                    Spacer()

                    Button(action: {
                        
                        Task {
                            // delete currently selected photo from photo album
                            await self.cameraModel.selectedAsset?.delete()

                            // refresh collection of photo
                            await self.cameraModel.photoCollection.refreshPhotoAssets()

                            // refresh selected images in UI
                            self.cameraModel.selectedAsset = nil
                            self.cameraModel.selectedImage = nil
                        }
                        
                    }) {
                        Image(systemName: "trash.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height: 30)
                    }

                    Button(action: {
                        
                        self.cameraModel.state = .capturePhoto
                        
                    }) {
                        Image(systemName: "camera.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width:30, height: 30)
                            .padding()
                    }
                    
                }
                
                ScrollView {
                    LazyVGrid(columns: columns(containerWidth: actualWidth),
                              spacing: itemSpacing) {
                        
                        ForEach(photoCollection.photoAssets) { asset in
                            smallPhotoItemView(asset: asset, containerWidth: actualWidth)
                        }
                    }
                }
            }
            .frame(width: actualWidth, height: actualHeight)
        }
    }
    
    @ViewBuilder
    private func smallPhotoItemView(asset: PhotoAsset, containerWidth: CGFloat) -> some View {
        let photoCollection = cameraModel.photoCollection
        
        PhotoItemView(asset: asset,
                      cache: photoCollection.cache,
                      imageSize: imageSize(containerWidth: containerWidth))
        
        .frame(width: itemSize(containerWidth: containerWidth).width,
               height: itemSize(containerWidth: containerWidth).height)
        .clipped()
        .opacity(cameraModel.selectedAsset == asset ? 0.5 : 1.0)
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
                await self.cameraModel.selectedImage(asset: asset)
            }
        }
    }
}

struct PhotoCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCollectionView().environmentObject(CameraViewModel())
    }
}
