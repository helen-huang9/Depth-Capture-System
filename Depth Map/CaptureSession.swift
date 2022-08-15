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

class ImageCaptureManager: NSObject {
    
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureInput!
    var photoOutput: AVCapturePhotoOutput!
    var photoSettings: AVCapturePhotoSettings!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var imgNum: Int!
    
    override init() {
        super.init()
        self.imgNum = 0
        self.getCameraPermissions()
    }
    
    func getCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupCaptureSession() }
            }
        case .denied:
            return
        case .restricted:
            return
        @unknown default:
            fatalError("Unknown AVCaptureDevice authorization status")
        }
    }
    
    func startCaptureSession() {
        self.captureSession.startRunning()
    }
    
    func stopCaptureSession() {
        self.captureSession.stopRunning()
    }
    
    func capturePhoto() {
        let uniquePhotoSettings = AVCapturePhotoSettings(from: self.photoSettings)
        self.photoOutput.capturePhoto(with: uniquePhotoSettings, delegate: self)
    }
    
    func setupCaptureSession() {
        self.captureSession = AVCaptureSession()
        
        self.captureSession.beginConfiguration()
        // Set an AVCaptureDevice for captureSession input
        // This is for the front camera, which uses TrueDepth camera
//        guard let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .depthData, position: .unspecified)
//            else { fatalError("No true depth camera.") }
        
        // This is for the back camera, which uses dual cameras
        guard let device = AVCaptureDevice.default(.builtInDualCamera, for: .depthData, position: .unspecified)
            else { fatalError("No dual lense camera.") }
        
        // This is for the back camera, which uses dual wide cameras (Lo's phone)
//        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .depthData, position: .unspecified)
//            else { fatalError("No dual wide lense camera.") }
        
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
    
    
    func configurePhotoSettings() {
        self.photoSettings = AVCapturePhotoSettings()
        self.photoSettings.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
        self.photoSettings.isDepthDataFiltered = self.photoOutput.isDepthDataDeliverySupported
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
        guard error == nil else { print("Error capturing photo: \(error!)"); return }

        // Get Photo library authorization from user
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                // Add the captured photo's file data as the main resource for the Photos asset.
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            }, completionHandler: self.handlePhotoLibraryError)
        }
        
        // Convert relevant depth data to Data object of format 'JSON'
        let convertedDepthMap = photo.depthData!.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32).depthDataMap
        guard let cameraCalibrationData = photo.depthData!.cameraCalibrationData else { fatalError("No camera calibration data") }
        let jsonStringData = wrapImageData(depthMap: convertedDepthMap, calibration: cameraCalibrationData)
        
        let imgPath = "depth_\(self.imgNum!)"
        
        saveToFile(data: jsonStringData, path: imgPath)
        print("Finished saving data to file")
        self.imgNum += 1
    }
    
    /**
     Error handling for adding photo to photo library
     */
    func handlePhotoLibraryError(output: Bool, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!.localizedDescription)"); return }
        if (output) {
            print("Photo successfully added to Photo Library")
        } else {
            print("Photo was not added to Photo Library")
        }
    }
    
    /**
     Convert depth data to be a 2D array of floats
     */
    func convertDepthData(depthMap: CVPixelBuffer) -> [[Float32]] {
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        print("Depth Data Width: \(width)")
        print("Depth Data Height: \(height)")
        var convertedDepthMap: [[Float32]] = Array(repeating: Array(repeating: 0, count: width), count: height)
        
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
        
        for row in 0 ..< height {
            for col in 0 ..< width {
                convertedDepthMap[row][col] = floatBuffer[width * row + col]
            }
        }
        CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 2))
        return convertedDepthMap
    }
    
    /**
     Converts depth map and calibration data into a 'Data' object in the a JSON format
     */
    func wrapImageData(depthMap: CVPixelBuffer, calibration: AVCameraCalibrationData) -> Data {
        let jsonDict: [String : Any] = [
            "calibration_data" : [
                "intrinsic_matrix" : (0 ..< 3).map{ x in
                    (0 ..< 3).map{ y in calibration.intrinsicMatrix[x][y]}
                },
                "pixel_size" : calibration.pixelSize,
                "intrinsic_matrix_reference_dimensions" : [
                    calibration.intrinsicMatrixReferenceDimensions.width,
                    calibration.intrinsicMatrixReferenceDimensions.height
                ]
            ],
            "depth_data" : convertDepthData(depthMap: depthMap)
        ]
        let jsonStringData = try! JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        return jsonStringData
    }
    
    /**
     Saves the inputted Data object (in the form of a JSON) to a document in the app's document folder
     */
    func saveToFile(data: Data, path: String) {
        print("Saving data to file")
        let URLpath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(path)
        print("URLPath: \(URLpath)")
        
        do {
            try data.write(to: URLpath)
        } catch {
            print("Error in saving to file: \(error.localizedDescription)")
        }
    }
}
