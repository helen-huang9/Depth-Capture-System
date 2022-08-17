//
//  PhotoCapture.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import AVFoundation
import Photos

extension PhotoCaptureManager: AVCapturePhotoCaptureDelegate {
    /// Called each time the user captures a photo.
    func capturePhoto() {
        let uniquePhotoSettings = AVCapturePhotoSettings(from: self.photoSettings)
        self.photoOutput.capturePhoto(with: uniquePhotoSettings, delegate: self)
        print("Captured Image")
    }
    
    /**
     Required for depth data delivery.
     - Parameters:
     - output: The photo output performing the capture.
     - photo: An object containing the captured image pixel buffer, along with any metdata and attachments captured along with thep photo (such as a preview image or depth map). This paramater is always non-nil: if an error prevented successful capture,, this object still contains metadata for the intended capture.
     - error: If the capture process could not proceed successfully, an error object describing the failure; otherwise, nil.
     */
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!)"); return }

        // Get Photo library authorization from user
        getPhotoLibraryPermissions(photo: photo)
        
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
     Convert depth data to be a 2D array of floats
     - Parameter depthMap: Depth data.
     - Returns: The depth data as a 2D array of floats.
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
     - Parameters:
     - depthMap: Depth data
     - calibration: Camera data
     - Returns: Data object in JSON format
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
