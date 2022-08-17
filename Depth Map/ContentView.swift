//
//  ContentView.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//

import SwiftUI
import AVFoundation

enum CaptureStatus {
    case on
    case off
}

struct ContentView: View {
    @ObservedObject private var captureManager = PhotoCaptureManager()
    @State private var captureStatus = CaptureStatus.off
    
    var body: some View {
        ZStack {
            if captureStatus == .off {
                InitialView(captureStatus: $captureStatus)
                    .environmentObject(captureManager)
            }
            else if captureStatus == .on {
                CaptureSessionView(captureStatus: $captureStatus)
                    .environmentObject(captureManager)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
