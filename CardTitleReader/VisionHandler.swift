//
//  VisionHandler.swift
//  CardScanner
//
//  Created by Reed Carson on 5/15/18.
//  Copyright © 2018 Reed Carson. All rights reserved.
//

import Foundation
import FirebaseMLVision

enum VisionResult<T> {
    case success(T)
    case error(Error)
}

class VisionHandler {
    
    let vision = Vision.vision()
    let textDetector: VisionTe
    lazy var textDetector = vision.onDeviceTextRecognizer()
    
    func processImage(_ image: UIImage, _ handler: @escaping (VisionResult<[VisionText]>) -> ()) {
    
        let image = VisionImage(image: image)
        
     //   textDetector = vision.textDetector()
        
        textDetector.detect(in: image) { (text, error) in
            if let error = error {
                handler(VisionResult.error(error))
                return
            }
            
            if let text = text {
                handler(VisionResult.success(text))
                return
            }
            
            let unknownError = NSError(domain: "Unknown Vision Error", code: 999, userInfo: nil)
            handler(VisionResult.error(unknownError))
        }
    }
    
    
    func processBuffer(_ buffer: CMSampleBuffer, withOrientation orientation: VisionDetectorImageOrientation? = nil, _ handler: @escaping (VisionResult<[VisionText]>) -> ()) {
        
        let image = VisionImage(buffer: buffer)
        
        if let orientation = orientation {
            let metadata = VisionImageMetadata()
            metadata.orientation = orientation
        }
        
        textDetector = vision.textDetector()
        
        textDetector.detect(in: image) { (text, error) in
            if let error = error {
                handler(VisionResult.error(error))
                return
            }
            
            if let text = text {
                handler(VisionResult.success(text))
                return
            }
            
            let unknownError = NSError(domain: "Unknown Vision Error", code: 999, userInfo: nil)
            handler(VisionResult.error(unknownError))
        }
    }
    
}
