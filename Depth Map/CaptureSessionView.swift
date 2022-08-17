//
//  CaptureSessionView.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import SwiftUI

struct CaptureSessionView: View {
    @EnvironmentObject var captureManager: PhotoCaptureManager
    @Binding var captureStatus: CaptureStatus
    
    var body: some View {
        ZStack {
            CapturePreviewView()
                .environmentObject(captureManager)
            VStack {
                HStack {
                    Button("Go Back") {
                        captureManager.stopCaptureSession()
                        captureStatus = .off
                    }
                    .padding(.top, 30.0)
                    .padding(.leading, 12.0)
                    Spacer()
                }
                Spacer()
                Button("Capture Image") {
                    captureManager.capturePhoto()
                }
                .padding(.all, 12.0)
                .foregroundColor(Color.black)
                .background(Color.white.cornerRadius(20))
                .padding(.bottom, 20.0)
            }
        }
    }
}
