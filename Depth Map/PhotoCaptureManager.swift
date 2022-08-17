//
//  PhotoCaptureManager.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//  Based on the "Capturing Photos with Depth" article: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_photos_with_depth#overview
//  And this person's article: https://frost-lee.github.io/rgbd-iphone/
//

import AVFoundation
import Photos

class PhotoCaptureManager: NSObject, ObservableObject {
    var captureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice?
    var captureDeviceInput: AVCaptureInput?
    var photoOutput = AVCapturePhotoOutput()
    var photoSettings = AVCapturePhotoSettings()
    
    var imgNum: Int!
    var devicePosition: AVCaptureDevice.Position = .back
    
    override init() {
        super.init()
        self.imgNum = 0
        if self.getCameraPermissions() {
            self.setupCaptureSession()
            print("Finished setting up capture session.")
        } else {
            print("Did not get camera permissions")
        }
    }
    
    /// Changes to capture session to use the inputted camera position upon its initialization. The camera position is either the front or back camera. 
    func changeCameraPositionTo(_ pos: AVCaptureDevice.Position) {
        devicePosition = pos
        // TODO: update capture device to reflect this change if capture session is running
    }
    
    /// Starts the capture session. This allows data to be collected.
    func startCaptureSession() {
        self.captureSession.startRunning()
        print("Started Capture Session")
    }
    
    /// Stops the capture session. This stops data from being collected.
    func stopCaptureSession() {
        self.captureSession.stopRunning()
        print("Stopped Capture Session")
    }
    
    
    /// Gets called if getting camera permissions was successful. Sets up the capture session for depth data delivery and configures the photo settings.
    func setupCaptureSession() {
        configureCaptureSession()
        enableDepthDelivery()
        configurePhotoSettings()
    }
    
    /// Configures the capture session by assigning the device input and photo output.
    func configureCaptureSession() {
        self.captureSession.beginConfiguration()
        // Set an AVCaptureDevice for captureSession input
        guard let device = getDevice() else { fatalError("Could not find compatible AVCaptureDevice.") }
        self.captureDevice = device
        guard let deviceInput = try? AVCaptureDeviceInput(device: device), self.captureSession.canAddInput(deviceInput) else { fatalError("Can't add video input.") }
        self.captureSession.addInput(deviceInput)
        self.captureDeviceInput = deviceInput
        
        // Set an AVCapturePhotoOutput for captureSession output
        guard self.captureSession.canAddOutput(self.photoOutput) else { fatalError("Can't add photo output.") }
        self.captureSession.addOutput(self.photoOutput)
        self.captureSession.sessionPreset = .photo
        
        // Select a depth (not disparity) format that works with the active color format
        do {
            guard let device = self.captureDevice else { fatalError("No capture device found for depth formatting.") }
            try device.lockForConfiguration()
            let availableFormats = device.activeFormat.supportedDepthDataFormats
            let depthFormat = availableFormats.filter { format in
                let pixelFormatType = CMFormatDescriptionGetMediaSubType(format.formatDescription)
                
                return (pixelFormatType == kCVPixelFormatType_DepthFloat32 ||
                        pixelFormatType == kCVPixelFormatType_DepthFloat16)
            }.first
            device.activeDepthDataFormat = depthFormat
            device.unlockForConfiguration()
        } catch {
            fatalError("Couldn't configure capture device to have depth format.")
        }
        
        // Save configurations for captureSession
        self.captureSession.commitConfiguration()
    }
    
    /// Creates and configures the photo settings used for all photos.
    func configurePhotoSettings() {
        self.photoSettings.isDepthDataDeliveryEnabled = true
        self.photoSettings.isDepthDataFiltered = true
    }
    
    /// Returns the first device that satisfies the accepted deviceTypes. Is dependent on the device position stored in devicePosition.
    func getDevice() -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTrueDepthCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTripleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .depthData, position: .unspecified)
        let devices = discoverySession.devices
        guard !devices.isEmpty else { fatalError("Missing capture devices.")}
        return devices.first(where: { device in device.position == self.devicePosition })!
    }
    
    /// Enable depth data delivery for photo output. Throw an error if depth data is not supported.
    func enableDepthDelivery() {
        guard self.photoOutput.isDepthDataDeliverySupported else { fatalError("Photo output does not support depth data.") }
        self.photoOutput.isDepthDataDeliveryEnabled = true
    }
}
