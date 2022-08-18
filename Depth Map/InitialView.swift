//
//  InitialView.swift
//  Depth Map
//
//  Created by Helen Huang on 8/16/22.
//

import SwiftUI

enum CameraPosition: String {
    case back = "Back"
    case front = "Front"
}

struct InitialView: View {
    @EnvironmentObject var captureManager: PhotoCaptureManager
    @Binding var captureStatus: CaptureStatus
    
    @State private var dir = ""
    @State private var showingAlert = false
    @State private var camPos = CameraPosition.back
    
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
                if dir.isEmpty {
                    return Alert(title: Text("Cannot have an empty folder name"),
                                 message: Text("Please input a folder name."))
                } else {
                    return Alert(title: Text("\"\(dir)\" already exists!"),
                                 message: Text("Please choose another folder name."),
                                 primaryButton: .default(
                                    Text("Ok"),
                                    action: {}),
                                 secondaryButton: .destructive(
                                    Text("Delete Original Folder"),
                                    action: {
                                        captureManager.removeDirectory(dirName: dir)
                                    }))
                }
            }
            Spacer()
            VStack {            
                Text("Settings").font(.title2)
                horizontalLine()
                HStack {
                    Text("Depth Data Directory:")
                        .frame(width: 180, alignment: .leading)
                    TextField("name", text: $dir)
                        .multilineTextAlignment(.trailing)
                }
                .padding([.leading, .trailing], 20)
                horizontalLine()
                HStack {
                    Text("Using camera position:")
                    Spacer()
                    Button("\(camPos.rawValue)") {
                        if camPos == CameraPosition.front {
                            captureManager.changeCameraPositionTo(.back)
                            camPos = CameraPosition.back
                        } else {
                            captureManager.changeCameraPositionTo(.front)
                            camPos = CameraPosition.front
                        }
                    }
                    .frame(alignment: .trailing)
                }
                .padding([.leading, .trailing], 20)
                horizontalLine()
            }
            Spacer()
        }
    }
}

struct horizontalLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .frame(height: 1, alignment: .center)
            .padding([.leading, .trailing], 20)
    }
}
