//
//  main.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/25/24.
//


import Foundation
import UIKit


//let gbkData = Data(bytes: [0xc4, 0xe3, 0xba, 0xc3]) // "你好"的GBK编码
// 
//
//extension String.Encoding{
//    public static let gbk: String.Encoding = {
//        let cfEnc = CFStringEncodings.GB_18030_2000
//        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
//        let gbk = String.Encoding.init(rawValue: enc)
//        return gbk
//    }()
//}
//
//// 将数据转换为字符串
//if let string = String(data: gbkData, encoding: .gbk) {
//    print(string) // 输出: 你好
//} else {
//    print("无法解码的数据")
//}

let URLsPath = "/Users/royzhao/Library/CloudStorage/OneDrive-UniversityofIllinois-Urbana/Coding/PunctualPath/PunctualPath/urls.json"
getURLs(path: URLsPath)
let bs = BeijingSubway.fromJsonFile(URLsPath)
let urls = bs?.getLine("1号线/八通线")?.getStation("古城")?.getTbUrls(for: .weekday)

urls?.getImg { image in
    if let image = image {
        print("Image downloaded successfully")
        // Update the UI on the main thread
        DispatchQueue.main.async {
            // Assuming you have an imageView to display the image
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
            // Add imageView to your view hierarchy
            // Example: self.view.addSubview(imageView) if you are inside a UIViewController
        }
    } else {
        print("Failed to download image")
    }
}
