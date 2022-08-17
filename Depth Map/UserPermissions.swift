//
//  UserPermissions.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import AVFoundation
import Photos

extension PhotoCaptureManager {
    /// Get camera permission from user for AVCaptureDevice use.
    func getCameraPermissions() -> Bool {
        var status = false
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            status = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { status = true }
            }
        case .denied:
            status = false
        case .restricted:
            status = false
        @unknown default:
            fatalError("Unknown AVCaptureDevice authorization status")
        }
        return status
    }
    
    /// Get photo library permssions from the user to save the RGB images.
    /// - Parameter photo: AVCapturePhoto used to create the PHAssetCreationRequest
    func getPhotoLibraryPermissions(photo: AVCapturePhoto) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            }, completionHandler: self.handlePhotoLibraryError)
        }
    }
    
    /// Error handling for adding photo to photo library
    func handlePhotoLibraryError(output: Bool, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!.localizedDescription)"); return }
        if (output) {
            print("Photo successfully added to Photo Library")
        } else {
            print("Photo was not added to Photo Library")
        }
    }
}
