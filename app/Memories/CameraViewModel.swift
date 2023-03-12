//
//  AddMemoryViewModel.swift
//  Memories
//
//  Created by Stormacq, Sebastien on 07/03/2023.
//

import AVFoundation
import SwiftUI
import os.log

// MARK: Camera and Photo gallery support
@MainActor
final class CameraViewModel: ObservableObject {
    
    enum PhotoState {
        case loadingPhoto
        case albumLoaded
        case capturePhoto
        case photoSelected(UIImage)
        case uploading
    }
    @Published var state: PhotoState = .loadingPhoto
    
    let camera = Camera()
    let photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
    
    @Published var viewfinderImage: Image?
    @Published var selectedImage: UIImage? // to display in photocollection view
    @Published var selectedAsset: PhotoAsset? // for comparison in photocollection view

    init() {
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }

        for await image in imageStream {
            Task { @MainActor in
                viewfinderImage = image
            }
        }
    }
    
    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { await self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            savePhoto(imageData: photoData.imageData)
        }
    }
    
    private func unpackPhoto(_ photo: AVCapturePhoto) -> PhotoData? {
        guard let imageData = photo.fileDataRepresentation() else { return nil }

        guard let previewCGImage = photo.previewCGImageRepresentation(),
           let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
              let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation) else { return nil }
        let imageOrientation = Image.Orientation(cgImageOrientation)
        let thumbnailImage = Image(decorative: previewCGImage, scale: 1, orientation: imageOrientation)
        
        let photoDimensions = photo.resolvedSettings.photoDimensions
        let imageSize = (width: Int(photoDimensions.width), height: Int(photoDimensions.height))
        let previewDimensions = photo.resolvedSettings.previewDimensions
        let thumbnailSize = (width: Int(previewDimensions.width), height: Int(previewDimensions.height))
        
        return PhotoData(thumbnailImage: thumbnailImage, thumbnailSize: thumbnailSize, imageData: imageData, imageSize: imageSize)
    }
    
    func savePhoto(imageData: Data) {
        Task {
            do {
                try await photoCollection.addImage(imageData)
                await self.selectedImage(asset: photoCollection.photoAssets[0]) // refresh the UI
                logger.debug("Added image data to photo collection.")
            } catch let error {
                logger.error("Failed to add image to photo collection: \(error.localizedDescription)")
            }
        }
    }
    
    func loadPhotos() async {
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }
        
        Task { 
            do {
                try await self.photoCollection.load()
            } catch let error {
                logger.error("Failed to load photo collection: \(error.localizedDescription)")
            }
            await self.selectedImage(asset: self.photoCollection.photoAssets[0])
            self.state = .albumLoaded
        }
    }

    func selectedImage(asset: PhotoAsset) async {
        if let pha = asset.phAsset {
            let pictureSize = CGSize(width: pha.pixelWidth,
                                     height: pha.pixelHeight)
            let image = await asset.uiImage(in: photoCollection.cache,
                                            targetSize: pictureSize)
            self.selectedImage = image
            self.selectedAsset = asset // for comparison in photocollection view
        } else {
            fatalError("Asset has no phAsset")
        }

    }
    
    func takePhoto() {
        self.camera.takePhoto()
        self.state = .albumLoaded
    }
}

fileprivate struct PhotoData {
    var thumbnailImage: Image
    var thumbnailSize: (width: Int, height: Int)
    var imageData: Data
    var imageSize: (width: Int, height: Int)
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate extension Image.Orientation {

    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "DataModel")
