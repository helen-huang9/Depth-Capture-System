//
//  CapturePreviewView.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import SwiftUI
import AVFoundation

struct CapturePreviewView: UIViewRepresentable {
    @EnvironmentObject var captureManager: PhotoCaptureManager
    
    func makeUIView(context: Context) -> some UIView {
        let preview = UIPreviewView()
        preview.videoPreviewLayer.session = captureManager.captureSession
        preview.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        return preview
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

class UIPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
