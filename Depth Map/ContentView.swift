//
//  ContentView.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//

import SwiftUI

enum CaptureStatus: String {
    case off = "circle"
    case on = "circle.fill"
}

struct ContentView: View {
    let captureSession = ImageCaptureManager()
    
    @State var symbol = CaptureStatus.off
    @State var cameraPos = "back"
    
    var body: some View {
        VStack {
            if self.symbol == CaptureStatus.on {
                Image(systemName: self.symbol.rawValue)
                    .foregroundColor(Color.green)
            } else {
                Image(systemName: self.symbol.rawValue)
                    .foregroundColor(Color.red)
            }
            Spacer()
            Text("Capture Session").font(.title)
            Button("Start Capture Session") {
                print("Started Capture Session")
                self.symbol = CaptureStatus.on
                captureSession.startCaptureSession()
            }
            .padding(.all, 10.0)
            .background(Color(red: 0.85, green: 0.85, blue: 0.9, opacity: 0.85).cornerRadius(20))
            .disabled(self.symbol == CaptureStatus.on)
            
            Button("Stop Capture Session") {
                print("Stopped Capture Session")
                self.symbol = CaptureStatus.off
                captureSession.stopCaptureSession()
            }
            .padding(.all, 10.0)
            .background(Color(red: 0.85, green: 0.85, blue: 0.9, opacity: 0.85).cornerRadius(20))
            .disabled(self.symbol == CaptureStatus.off)
            
            Spacer()
            
            Text("Settings").font(.title)
            HStack {
                Text("Using \(self.cameraPos) camera")
                Button("Change") {
                    if cameraPos == "back" {
                        captureSession.changeCameraPositionTo(.front)
                        self.cameraPos = "front"
                    } else {
                        captureSession.changeCameraPositionTo(.back)
                        self.cameraPos = "back"
                    }
                }
                .padding(.all, 10.0)
            }
            .disabled(self.symbol == CaptureStatus.on)
            
            Spacer()
            
            Button("Capture Image") {
                print("Captured Image")
                captureSession.capturePhoto()
            }
            .padding(.all, 12.0)
            .background(Color(red: 0.85, green: 0.85, blue: 0.9, opacity: 0.85).cornerRadius(20))
            .disabled(self.symbol == CaptureStatus.off)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
