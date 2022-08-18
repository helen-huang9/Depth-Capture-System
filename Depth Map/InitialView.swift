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
    
    @State private var dir = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            Spacer()
            Text("Capture Session").font(.title)
            Button("Start Capture Session") {
                if !dir.isEmpty && captureManager.createDirectory(dirName: dir) {
                    captureManager.startCaptureSession()
                    captureStatus = .on
                } else {
                    showingAlert = true
                }
            }
            .padding(.all, 10.0)
            .foregroundColor(Color.black)
            .background(Color(red: 0.85, green: 0.85, blue: 0.9, opacity: 0.85).cornerRadius(20))
            .alert(isPresented: $showingAlert) {
                var textAlert = Text("\"\(dir)\" already exists!")
                if dir.isEmpty { textAlert = Text("Cannot have an empty folder name") }
                return Alert(title: textAlert,
                             message: Text("Please choose another folder name."),
                             dismissButton: .default(Text("Got it!")))
            }
            Spacer()
            Text("Settings").font(.title2)
            HStack {
                Text("Depth Data Directory:")
                    .padding(.leading, 20)
                    .frame(width: 200, alignment: .leading)
                TextField("name", text: $dir)
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing, 20)
            }
            Spacer()
        }
    }
}
