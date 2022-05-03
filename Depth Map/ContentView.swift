//
//  ContentView.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//

import SwiftUI

struct ContentView: View {
    let captureSession = ImageCaptureManager()
    var body: some View {
        VStack {
            Button("Start Capture Session") {
                print("Started Capture Session")
                captureSession.startRunning()
            }.padding(.all, 10.0)
            Spacer()
            Button("Capture Image") {
                print("Capture Image button clicked")
                captureSession.capturePhoto()
            }.padding(.all, 10.0)
            Spacer()
            Button("Stop Capture Session") {
                print("Stopped Capture Session")
                captureSession.stopRunning()
            }.padding(.all, 10.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
