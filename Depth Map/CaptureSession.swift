//
//  CaptureSession.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//  Based on the "Capturing Photos with Depth" article: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_photos_with_depth#overview
//  And this person's article: https://frost-lee.github.io/rgbd-iphone/
//

import AVFoundation
import Photos
import UIKit


        
/** RESEARCH NOTES::
 AVCapturePhoto fields that might be useful:
 - .isRawPhoto() checks if contains RAW format data. If so, then .pixelBuffer() gets a CVPixelBuffer that is the uncompressed or RAW image samble buffer for the photo
 - protocol AVCapturePhotoFileDataRepresentationCustomizer that allows custom packaging for photo data
 - func fileDataRepresetation(): Generates and returns a flat data representation of the photo and its attachments
 - func cgImageRepresentation(): Extracts and returns the captured photo's primary image as a Core Graphics image object.
 */

/**
 Depth Data stuff!!!
 
 Documentation Note on Depth Data, Depth Map, and Disparity Map:
    "Depth data is a generic term for a map of per-pixel data containing depth-related information. A depth data object wraps a disparity or depth map and provides conversion methods, focus information, and camera calibration data to aid in using the map for rendering or computer vision tasks.
 
    A depth map describes at each pixel the distance to an object, in meters. depth = (baselineInMeters * focalLength) / (disparity [aka pixelShift])
 
    A disparity map describes normalized shift values for use in comparing two images. The value for each pixel in the map is in units of 1/meters: (pixelShift / (pixelFocalLength * baselineInMeters))."
 
 Documentation Note on Nonrectilinear Data in the Disparity/Depth MapsL
    "The capture pipeline generates disparity or depth maps from camera images containing nonrectilinear data. Camera lenses have small imperfections that cause small distortions in their resultant images compared to an ideal pinhole camera model, so AVDepthData maps contain nonrectilinear (nondistortion-corrected) data as well. The maps' values are warped to match the lens distortion characteristics present in the YUV image pixel buffers captured at the same time.
 
    Because a depth data map is nonrectilinear, you can use an AVDepthData map as a proxy for depth when rendering effects to its accompanying image, but not to correlate points in 3D space. To use depth data for computer vision tasks, use the data in the cameraCalibrationData property to rectify the depth data."
 */

class ImageCaptureManager: NSObject {
    
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureInput!
    var photoOutput: AVCapturePhotoOutput!
    var photoSettings: AVCapturePhotoSettings!
    
    override init() {
        super.init()
        
        /**
         This switch statement is based on the "Requesting Authorization for Media Capture on iOS". This function is to request permissino to capture photos on user's device
         https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios
         */
        // Get Camera permissions
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.setupCaptureSession()
            
            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupCaptureSession()
                    }
                }
            
            case .denied: // The user has previously denied access.
                return

            case .restricted: // The user can't grant access due to restrictions.
                return
        @unknown default:
            fatalError("Unknown AVCaptureDevice authorization status")
        }
        
        // Set up and configure capture session
//        setupCaptureSession()
        
        // Configure the capture photo settings used for all photos
//        configurePhotoSettings()
    }
    
    /**
     Start running the capture session
     */
    func startRunning() {
        self.captureSession.startRunning()
    }
    
    /**
     Stop running the capture session
     */
    func stopRunning() {
        self.captureSession.stopRunning()
    }
    
    /**
     This function calls the AVCapturePhotoOutput::capturePhoto() function that captures the actual photo. Have this as its own function so that it make be called over and over again for multiple photos.
     
     Note:
     "It is illegal to reuse a AVCapturePhotoSettings instance for multiple captures. Calling the capturePhoto(with:delegate:) method throws an exception (invalidArgumentException) if the settings object’s uniqueID value matches that of any previously used settings object.
     To reuse a specific combination of settings, use the init(from:) initializer to create a new, unique AVCapturePhotoSettings instance from an existing photo settings object."
     */
    func capturePhoto() {
        // Set up photosettings for photo capture
        let uniquePhotoSettings = AVCapturePhotoSettings(from: self.photoSettings)
        self.photoOutput.capturePhoto(with: uniquePhotoSettings, delegate: self)
    }
    
    /**
        This function is based on the "Capturing Photos with Depth" article. This function creates an AVCaptureSession, and configures it so that it takes an image that had depthData.
     This function is also where we create the AVCaptureDevice  and AVCapturePhotoOutput needed for the capture session
     */
    func setupCaptureSession() {
        // Initialize an AVCaptureSession
        self.captureSession = AVCaptureSession()
        
        // Tell captureSession we are going to configure it
        self.captureSession.beginConfiguration()
        
        // Set up an AVCaptureDevice for captureSession input
//        guard let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .depthData, position: .unspecified) // This is for the front camera, which uses TrueDepth camera
//            else { fatalError("No true depth camera.") }
        guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .depthData, position: .unspecified) // This is for the back camera, which uses dual cameras
            else { fatalError("No dual lense camera.") }
        self.captureDevice = device
        guard let deviceInput = try? AVCaptureDeviceInput(device: device), self.captureSession.canAddInput(deviceInput) else { fatalError("Can't add video input.") }
        self.captureSession.addInput(deviceInput)
        self.captureDeviceInput = deviceInput
        
        // Set an AVCapturePhotoOutput for captureSession output
        self.photoOutput = AVCapturePhotoOutput()
        guard self.captureSession.canAddOutput(self.photoOutput) else { fatalError("Can't add photo output.") }
        self.captureSession.addOutput(self.photoOutput)
        self.captureSession.sessionPreset = .photo
        
        // Select a depth (not disparity) format that works with the active color format
        do {
            try self.captureDevice.lockForConfiguration()
            let availableFormats = self.captureDevice.activeFormat.supportedDepthDataFormats
            let depthFormat = availableFormats.filter { format in
                let pixelFormatType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                
//                return pixelFormatType == kCVPixelFormatType_DepthFloat32
                return (pixelFormatType == kCVPixelFormatType_DepthFloat32 ||
                        pixelFormatType == kCVPixelFormatType_DepthFloat16)
            }.first
            self.captureDevice.activeDepthDataFormat = depthFormat
            self.captureDevice.unlockForConfiguration()
        } catch {
            fatalError("Couldn't configure capture device to have depth format.")
        }
        
        // Save configurations for captureSession
        self.captureSession.commitConfiguration()
        
        // Enable depth data delivery for photo output
        self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
        
        // Configure the capture photo settings used for all photos
        configurePhotoSettings()
    }
    
    /**
     This function was also based on the  "Capturing Photos with Depth" article linked above
     */
    func configurePhotoSettings() {
//        self.photoSettings = AVCapturePhotoSettings()
        self.photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        self.photoSettings.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
        self.photoSettings.isDepthDataFiltered = self.photoOutput.isDepthDataDeliverySupported
        self.photoSettings.isCameraCalibrationDataDeliveryEnabled = self.photoOutput.isCameraCalibrationDataDeliverySupported
    }
}

extension ImageCaptureManager: AVCapturePhotoCaptureDelegate {
    /**
     Required for depth data delivery.
     Params:
     - captureOutput: The photo output performing the capture
     - photo: An object containing the captured image pixel buffer, along with any metdata and attachments captured along with thep photo (such as a preview image or depth map). This paramater is always non-nil: if an error prevented successful capture,, this object still contains metadata for the intended capture.
     - error: If the capture process could not proceed successfully, an error object describing the failure; otherwise, nil
     */
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("Executing PhotoCaptureProcessor::photoOutput()")
        
        // Error Checking
        guard error == nil else { print("Error capturing photo: \(error!)"); return }

        /**
         This code block  is from the "Saving Captured Photos" article: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_still_and_live_photos/saving_captured_photos
         */
        // Get Photo library authorization from user
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            }, completionHandler: self.handlePhotoLibraryError)
        }
        
        //============================= Start of fucking around code block ==============================================
        
        guard let depthData = photo.depthData else { fatalError("No depth data captured.") } // AVDepthData class
        var depthDataMap = depthData.depthDataMap
        
        // Failed attempt to convert to UIImage to add to photos album
//        if depthData.depthDataType != kCVPixelFormatType_DepthFloat32 {
//            depthDataMap = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32).depthDataMap
//        }
//        depthDataMap.normalize()
//        let ciImage = CIImage(cvPixelBuffer: depthDataMap)
//        let uiImage = UIImage(ciImage: ciImage)
//        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        
        // Failed attempt converting to Data to insert to add to PHPhotoLibrary
//        print("CVPixelBufferPlaneCount: \(CVPixelBufferGetPlaneCount(depthDataMap))")
//        print("CVPixelBuffer:\(depthDataMap)")
//        let test = Data.from(pixelBuffer: depthDataMap)
//        print("test Data object has \(test.count) bytes")
        
//        guard let cameraCalibrationData = photo.cameraCalibrationData else { fatalError("No camera calibration data captured.") } // AVCameraCalibrationData class
        
        // Checking what photo formats I can output. Just out of curiosity, maybe don't need to care about this
//        print("Available Photo Pixel Format Types: \(output.availablePhotoPixelFormatTypes)")
//        print("Available Photo File Types: \(output.availablePhotoFileTypes)")
//        print("Captured Photo metadata: \(photo.metadata)")
        
        //============================= End of fucking around code block ==============================================
    }
    
    /**
     Error handling for adding photo to photo library
     */
    func handlePhotoLibraryError(output: Bool, error: Error?) {
        // Error Checking
        guard error == nil else { print("Error capturing photo: \(error!.localizedDescription)"); return }
        
        if (output) {
            print("Photo successfully added to Photo Library")
        } else {
            print("Photo was not added to Photo Library")
        }
    }
}



























extension Data {
    public static func from(pixelBuffer: CVPixelBuffer) -> Self {
        CVPixelBufferLockBaseAddress(pixelBuffer, [.readOnly])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, [.readOnly]) }

        // Calculate sum of planes' size
        var totalSize = 0
        let height      = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        let planeSize   = height * bytesPerRow
        totalSize += planeSize
//        for plane in 0 ..< CVPixelBufferGetPlaneCount(pixelBuffer) {
//            let height      = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
//            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
//            let planeSize   = height * bytesPerRow
//            totalSize += planeSize
//        }
        print("totalSize = \(totalSize)")

        guard let rawFrame = malloc(totalSize) else { fatalError() }
        var dest = rawFrame

        for plane in 0 ..< CVPixelBufferGetPlaneCount(pixelBuffer) {
            let source      = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane)
            let height      = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            let planeSize   = height * bytesPerRow

            memcpy(dest, source, planeSize)
            dest += planeSize
        }

        return Data(bytesNoCopy: rawFrame, count: totalSize, deallocator: .free)
    }
}

extension CVPixelBuffer {
  func normalize() {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
    
    var minPixel: Float = 1.0
    var maxPixel: Float = 0.0
    
    /// You might be wondering why the for loops below use `stride(from:to:step:)`
    /// instead of a simple `Range` such as `0 ..< height`?
    /// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
    /// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
    /// which is eactly what happens when running this sample project in Debug mode.
    /// If this was a production app then it might not be worth worrying about but it is still
    /// worth being aware of.
    
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    
    let range = maxPixel - minPixel
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = floatBuffer[y * width + x]
        floatBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }
    
    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
  }
}
