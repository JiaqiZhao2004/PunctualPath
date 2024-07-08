//
//  ImageProcessing.swift
//  PunctualPath
//
//  Created by Roy Zhao on 7/8/24.
//

import Foundation
import UIKit
import Vision

func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
    guard let cgImage = image.cgImage else {
        completion([])
        return
    }
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion([])
            return
        }
        
        let recognizedStrings = observations.compactMap { observation in
            return observation.topCandidates(1).first?.string
        }
        
        completion(recognizedStrings)
    }
    
    request.recognitionLevel = .accurate
    
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing text recognition: \(error)")
        completion([])
    }
}
