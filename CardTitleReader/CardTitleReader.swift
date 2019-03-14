//
//  MTGTitleReader.swift
//  CardScanner
//
//  Created by Reed Carson on 6/8/18.
//  Copyright © 2018 Reed Carson. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseMLVision

public struct TextElement {
    public var text: String
    public var frame: CGRect
}

public protocol CardTitleReaderDelegate {
    func didDetectTitle(_ title: String)
 //   func didDetectFrameForVisionElement(_ frame: CGRect)
    func didReceiveProcessingError(_ error: Error)
    func didDetectElement(_ element: TextElement)
}

public class CardTitleReader {
    private let textProcessor: VisionTextProcessor
    private let visionHandler: VisionHandler
    private let requiredBuffers: Int
    private var bufferImageForSizing: UIImage?
    
    var accuracyRequired: Double = 0.75 // raise for higher performance, slower speed.   0 - 1
    var visionResultsProcessingFrequency = 10 // raise for higher performance, slower speed
    var validRectForReading: CGRect?
    
    private var buffersAnalyzed = 0
    
    public var readerDelegate: CardTitleReaderDelegate?
    
    public init(requiredBuffers: Int = 10) {
        self.requiredBuffers = requiredBuffers
        textProcessor = VisionTextProcessor()
        visionHandler = VisionHandler()
    }

    public func reset() {
        textProcessor.clear()
        buffersAnalyzed = 0
    }
    
    public func processSampleBuffer(_ buffer: CMSampleBuffer, withOrientation orientation: VisionDetectorImageOrientation? = nil) {
        visionHandler.processBuffer(buffer, withOrientation: orientation, { (result) in
            switch result {
            case .success(let visionText):
                self.handleProcessBufferSuccess(buffer, visionText)
            case .error(let error):
                self.readerDelegate?.didReceiveProcessingError(error)
            }
        })
    }
    
    private func handleProcessBufferSuccess(_ buffer: CMSampleBuffer, _ visionText: [VisionText]) {
        if bufferImageForSizing == nil {
            bufferImageForSizing = getImageFromBuffer(buffer)
        }
        
        buffersAnalyzed += 1
        
        for feature in visionText {
            if let block = feature as? VisionTextBlock {
                for line in block.lines {
                    let adjustedLineFrame = self.getAdjustedVisionElementFrame(line.frame)
                    let validVisionBounds = validRectForReading ?? UIScreen.main.bounds
                    if validVisionBounds.contains(adjustedLineFrame.origin) {
                        let textElement = TextElement(text: line.text, frame: line.frame)
                      //  readerDelegate?.didDetectFrameForVisionElement(adjustedLineFrame)
                        textProcessor.textElements.append(textElement)
                        readerDelegate?.didDetectElement(textElement)
                    }
                }
            }
        }
        
        if (buffersAnalyzed % visionResultsProcessingFrequency == 0) {
            let possibleTitles = textProcessor.getTopXTitles(3, withAccuracy: accuracyRequired)
            if possibleTitles.count == 1 {
                let title = possibleTitles[0]
                readerDelegate?.didDetectTitle(title)
            }
        }
    }

    private func getAdjustedVisionElementFrame(_ elementFrame: CGRect) -> CGRect {
        let screen = UIScreen.main.bounds
        var frame = elementFrame
        if let image = self.bufferImageForSizing {
            let xRatio = screen.width / image.size.width
            let yRatio = screen.height / image.size.height
            frame = CGRect(x: frame.minX * xRatio, y: frame.minY * yRatio, width: frame.width * xRatio, height: frame.height * yRatio)
        }
        return frame
    }
    
    private func getImageFromBuffer(_ buffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            print("Could not create pixel buffer")
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: ciImage)
    }
}
