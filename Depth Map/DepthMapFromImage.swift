//
//  DepthMapFromImage.swift
//  Depth Map
//
//  Created by Helen Huang on 4/27/22.
//

import Foundation
import AVFoundation

class DepthMapFromImage: NSObject {
    var depthData: AVDepthData!
    
    init(imageData: Data) {
        super.init()
        self.depthData = depthData(from: imageData)
    }
    
    func depthData(from imageData: Data) -> AVDepthData? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
            else { return nil }
        guard let auxiliaryData = CGImageSourceCopyAuxiliaryDataInfoAtIndex(imageSource, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable: Any]
            else { return nil }
        guard let depthData = try? AVDepthData(fromDictionaryRepresentation: auxiliaryData)
            else { return nil }
        return depthData
    }
}
