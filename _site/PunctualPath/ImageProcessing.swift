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

func isColorInRange(r: Int, g: Int, b: Int) -> Bool {
    var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0
    UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0).getHue(&h, saturation: &s, brightness: &v, alpha: nil)
    return (0.55...0.7).contains(h) && (0.01...1.0).contains(s) && (65...240).contains(Int(v * 255))
}

func increaseContrast(image: UIImage) -> UIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }
    let filter = CIFilter(name: "CIColorControls")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    filter?.setValue(2.0, forKey: kCIInputContrastKey) // Increase contrast
    guard let outputCIImage = filter?.outputImage else { return nil }
    return UIImage(ciImage: outputCIImage)
}

func filterImage(img: UIImage) -> UIImage? {
    guard let cgImage = img.cgImage else { return nil }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let width = cgImage.width
    let height = cgImage.height
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    let context = CGContext(data: &pixelData,
                            width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    
    guard let context = context else { return nil }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * bytesPerPixel
            let r = CGFloat(pixelData[offset]) / 255.0
            let g = CGFloat(pixelData[offset + 1]) / 255.0
            let b = CGFloat(pixelData[offset + 2]) / 255.0
            
            if !isColorInRange(r: Int(r * 255), g: Int(g * 255), b: Int(b * 255)) {
                pixelData[offset] = 255
                pixelData[offset + 1] = 255
                pixelData[offset + 2] = 255
            }
        }
    }
    
    guard let outputCGImage = context.makeImage() else { return nil }
    return UIImage(cgImage: outputCGImage)
}

func locateNthColorChange(img: UIImage,
                          n: Int,
                          vertical: Bool,
                          start: CGPoint,
                          step: Int = 1,
                          skip: Int = 1,
                          skipX: Int = 0,
                          skipY: Int = 0,
                          percentage: Bool = false,
                          toleranceHigh: Int = 100,
                          toleranceLow: Int = 5,
                          annotate: Bool = false) -> CGPoint {
    
    guard let cgImage = img.cgImage else {
        fatalError("Failed to get CGImage from UIImage")
    }
    
    let width = cgImage.width
    let height = cgImage.height
    var x: Int = 0
    var y: Int = 0
    if start.x < 1 {
        x = Int(start.x * CGFloat(width))
    } else {
        x = Int(start.x)
    }
    
    if start.y < 1 {
        y = Int(start.y * CGFloat(height))
    } else {
        y = Int(start.y)
    }
    
    
    if skipX == 0 && skipY == 0 {
        if vertical {
            y += skip
        } else {
            x += skip
        }
    } else {
        x += skipX
        y += skipY
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    let context = CGContext(data: &pixelData,
                            width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
    
    guard let context = context else {
        fatalError("Failed to create CGContext")
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    let offsetInitial = (y * width + x) * bytesPerPixel
    var rPrev: Int = Int(pixelData[offsetInitial]), gPrev: Int = Int(pixelData[offsetInitial + 1]), bPrev: Int = Int(pixelData[offsetInitial + 2])
    var colorChangeCount = 0
    var changing = false
    
    while colorChangeCount < n && 0 < x && x < width - step && 0 < y && y < height - step {
        if vertical {
            y += step
        } else {
            x += step
        }
        
        let offset = (y * width + x) * bytesPerPixel
        let r = Int(pixelData[offset])
        let g = Int(pixelData[offset + 1])
        let b = Int(pixelData[offset + 2])
        
        let rgbChange = abs(r - rPrev) + abs(g - gPrev) + abs(b - bPrev)
        
        if rgbChange > toleranceHigh && !changing {
            colorChangeCount += 1
            changing = true
            
            if annotate {
                // Assuming annotating by setting pixels to black
                let annotateRadius = 3
                for dx in [-annotateRadius, annotateRadius] {
                    for dy in [-annotateRadius, annotateRadius] {
                        let ax = x + dx
                        let ay = y + dy
                        if ax >= 0 && ax < width && ay >= 0 && ay < height {
                            let annotateOffset = (ay * width + ax) * bytesPerPixel
                            pixelData[annotateOffset] = 0 // Red component
                            pixelData[annotateOffset + 1] = 0 // Green component
                            pixelData[annotateOffset + 2] = 0 // Blue component
                        }
                    }
                }
            }
        } else if rgbChange < toleranceLow && changing {
            changing = false
        }
        
        rPrev = r
        gPrev = g
        bPrev = b
    }
    
    if percentage {
        return CGPoint(x: CGFloat(x) / CGFloat(width), y: CGFloat(y) / CGFloat(height))
    } else {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

func locateHourStrip(img: UIImage, verbose: Bool = false) -> (CGPoint, CGPoint) {
    let left0 = locateNthColorChange(img: img, n: 2, vertical: false, start: CGPoint(x: 0.02, y: 0.4), toleranceHigh: 50)
    let left = locateNthColorChange(img: img, n: 1, vertical: true, start: left0, skipX: 1, skipY: 1)
    let right = locateNthColorChange(img: img, n: 1, vertical: false, start: left)
    
    if verbose {
        print("Hour Strip", left, right)
    }
    
    return (left, right)
}

func locateRowPositions(img: UIImage, hourStripRight: CGPoint, verbose: Bool = false) -> [Int] {
    let hourStripTopRight = locateNthColorChange(img: img, n: 1, vertical: true, start: hourStripRight, step: -1, skipX: 8, toleranceHigh: 100, annotate: true)
    
    let row1B = locateNthColorChange(img: img, n: 1, vertical: true, start: hourStripTopRight, step: 1, skipX: 1, skipY: 5, toleranceHigh: 20, annotate: true)
    let rowHeight = row1B.y - hourStripTopRight.y
    
    if verbose {
        print("Hour Strip Top Right", hourStripTopRight)
        print("Row Width", rowHeight)
    }
    
    var rowB = row1B
    var rows = [hourStripTopRight.y, row1B.y]
    
    while rowB.y < img.size.height - CGFloat(rowHeight) * 1.5 {
        let rowBR = locateNthColorChange(img: img, n: 1, vertical: true, start: rowB, step: 1, skipY: Int(rowHeight * 0.9), toleranceHigh: 20, annotate: true)
        
        if rowBR.y - rows.last! > CGFloat(rowHeight) * 1.5 {
            let rowBL = locateNthColorChange(img: img, n: 1, vertical: true, start: rowB, step: 1, skipX: -12, skipY: Int(rowHeight * 0.9), toleranceHigh: 50, annotate: true)
            
            if rowBL.y - rows.last! > CGFloat(rowHeight) * 1.5 {
                break
            } else {
                rowB = CGPoint(x: rowBL.x + 12, y: rowBL.y)
            }
        } else {
            rowB = rowBR
        }
        rows.append(rowB.y)
    }
    
    return rows.map { Int($0) }
}

func replaceNonDigitsWithSingleSpace(in input: String) -> String {
    let pattern = "\\D+"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: input.utf16.count)
    return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: " ")
}

func formatMinutes(_ m: String) -> [Int] {
    var m = m.replacingOccurrences(of: "Z", with: "2").replacingOccurrences(of: "S", with: "5")
    m = replaceNonDigitsWithSingleSpace(in: m)
    let mList = m.split(separator: " ").map { String($0) }
    var newList: [Int] = []

    for (i, numStr) in mList.enumerated() {
        if numStr.isEmpty {
            continue
        }

        guard var numInt = Int(numStr) else { continue }

        if numInt > 59 && numInt < 1000 {
            let rmR = Int(numStr.prefix(2)) ?? 0
            let rmL = Int(numStr.suffix(2)) ?? 0

            let priorM: Int
            if i == 0 {
                priorM = -1
            } else {
                priorM = Int(mList[i - 1]) ?? 0
            }

            let nextM: Int
            if i == mList.count - 1 {
                nextM = 60
            } else {
                nextM = Int(mList[i + 1]) ?? priorM + 10
            }

            let midpoint = (nextM - priorM) / 2

            if !(priorM..<nextM).contains(rmR), (priorM..<nextM).contains(rmL) {
                numInt = rmL
            } else if !(priorM..<nextM).contains(rmL), (priorM..<nextM).contains(rmR) {
                numInt = rmR
            } else if (priorM..<nextM).contains(rmR), (priorM..<nextM).contains(rmL) {
                if abs(rmR - midpoint) < abs(rmL - midpoint) {
                    numInt = rmR
                } else {
                    numInt = rmL
                }
            } else {
                numInt = midpoint
                print("Failed to parse minute data \(numStr), using midpoint value \(midpoint)")
            }
        }

        if !newList.contains(numInt) {
            newList.append(numInt)
        }
    }

    return newList
}

func loadTimetable(img: UIImage, filter: Bool = false, verbose: Bool = false) -> TimeTable {
    let (hourStripLeft, hourStripRight) = locateHourStrip(img: img, verbose: verbose)
    let rowPositions = locateRowPositions(img: img, hourStripRight: hourStripRight, verbose: verbose)
    
    let table = TimeTable()
    var hour = 4
    
    for i in 0..<rowPositions.count - 1 {
        let xLeft = Int(hourStripLeft.x)
        let xMiddle = Int(hourStripRight.x)
        let xRight = img.size.width
        let yTop = rowPositions[i]
        let yBottom = rowPositions[i + 1]
        
        let hCropRect = CGRect(x: xLeft, y: yTop, width: xMiddle - xLeft, height: yBottom - yTop)
        
        var hCrop = img.cropped(to: hCropRect)
            
        if filter {
            hCrop = filterImage(img: hCrop!)
            hCrop = increaseContrast(image: hCrop!)
        }
//        if verbose {
            // Display cropped and processed image
            // Assuming you have a method to display UIImage
//        displayImage(image: hCrop)
//        }
        
        var hRaw = 0
        
        do {
            if let image = hCrop {
                recognizeText(from: image) { ocrResult in
                    print("Hour")
                    print(ocrResult)
                    hRaw = Int(ocrResult[0]) ?? 0
                    
                    if hRaw != hour + 1 && hour != 23 {
                        if table.rows.count >= 3 && table.rows[table.rows.count - 1].hour == table.rows[table.rows.count - 2].hour + 1 && table.rows[table.rows.count - 1].hour == table.rows[table.rows.count - 3].hour + 2 {
                            hour += 1
                            if hour == 24 {
                                hour = 0
                            }
                            print("Hour recognized incorrectly at \(hour) (\(hRaw))")
                        }
                    } else {
                        hour = hRaw
                    }
                }
                
            }
        } catch {
            hour += 1
            if hour == 24 {
                hour = 0
            }
            print("Hour not recognized at \(hour)")
        }
        
        let row = Row(hour: hour)
        
        let mCropRect = CGRect(x: xMiddle, y: yTop, width: Int(xRight) - xMiddle, height: yBottom - yTop)
        var mCrop = img.cropped(to: mCropRect)
        
        if filter {
            mCrop = filterImage(img: mCrop!)
            mCrop = increaseContrast(image: mCrop!)
        }
        
//        if verbose {
//            // Display cropped and processed image
//            // Assuming you have a method to display UIImage
//            displayImage(image: mCrop)
//        }
        
        do {
            if let image = mCrop {
                var minutes = ""
                recognizeText(from: image) { ocrResult in
                    for result in ocrResult {
                        print("Min")
                        print(result)
                        minutes += result + " "
                    }
                }
                                
                minutes = minutes.trimmingCharacters(in: .whitespaces)
//                
                let formattedMinutes = formatMinutes(minutes)
                row.minutes = formattedMinutes
                table.addRow(row)
            }
        } catch {
            print("Failed to recognize minutes")
        }
    }
    
    return table
}

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
