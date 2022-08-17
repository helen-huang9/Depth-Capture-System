//
//  InitialView.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import SwiftUI

struct InitialView: View {
    @EnvironmentObject var captureManager: PhotoCaptureManager
    @Binding var captureStatus: CaptureStatus
    @State var dir = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("Capture Session").font(.title)
            Button("Start Capture Session") {
                captureManager.startCaptureSession()
                captureStatus = .on
            }
            .padding(.all, 10.0)
            .background(Color(red: 0.85, green: 0.85, blue: 0.9, opacity: 0.85).cornerRadius(20))
            Spacer()
            Text("Settings").font(.title2)
            HStack {
                Text("Depth Data Directory:")
                    .padding(.leading, 20)
                TextField("name", text: $dir)
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing, 20)
            }
            Spacer()
        }
    }
}
