//
//  ContentView.swift
//  Depth Map
//
//  Created by Helen Huang on 4/26/22.
//

import SwiftUI

struct ContentView: View {
    let captureSession = ImageCaptureManager()
    
    @State var symbol = "circle"
    
    var body: some View {
        VStack {
            Image(systemName: self.symbol)
            Button("Start Capture Session") {
                print("Started Capture Session")
                self.symbol = "circle.fill"
                captureSession.startCaptureSession()
            }.padding(.all, 10.0)
            Spacer()
            Button("Capture Image") {
                print("Captured Image")
                captureSession.capturePhoto()
            }.padding(.all, 10.0)
            Spacer()
            Button("Stop Capture Session") {
                print("Stopped Capture Session")
                self.symbol = "circle"
                captureSession.stopCaptureSession()
            }.padding(.all, 10.0)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
