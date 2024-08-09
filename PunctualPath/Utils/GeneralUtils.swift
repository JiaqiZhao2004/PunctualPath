//
//  ParsingUtils.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/9/24.
//

import Foundation

func trainDirectionFromURL(url: String?) -> String {
    guard let str = url else {
        return "数据获取错误"
    }
    // https://www.bjsubway.com/d/file/station/xtcx/line1/2023-12-30/1号线-八宝山站-古城站方向-工作日.jpg?=1
    guard let str2 = str.components(separatedBy: "/").last else {
        return str
    } // 1号线-八宝山站-古城站方向-工作日.jpg?=1
    guard let str3 = str2.components(separatedBy: "方向").first else {
        return str
    } // 1号线-八宝山站-古城站
    guard let str4 = str3.components(separatedBy: "-").last else {
        return str
    }
    return str4
}

func fetch(url: String, completion: @escaping (Data) throws -> Void) {
    print("Getting json from \(url)")
    guard let url = URL(string: url) else {
        return
    }
    Task {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Download error: Invalid response")
                return
            }
            try completion(data)
        } catch {
            print("Process error: \(error.localizedDescription)")
            return
        }
    }
}

extension String.Encoding {
    public static let gbk: String.Encoding = {
        let cfEnc = CFStringEncodings.GB_18030_2000
        let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        let gbk = String.Encoding.init(rawValue: enc)
        return gbk
    }()
}

extension String {
    func toPinyin() -> String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        return mutableString as String
    }
    
    func toPinyinAcronym() -> String {
        // Convert the string to pinyin
        let pinyins: [String] = self.toPinyin().components(separatedBy: " ")
        
        // Initialize an empty result string
        var acronym = ""
        
        // Iterate over each pinyin string
        for pinyin in pinyins {
            // Check if the pinyin contains a number and add it to the acronym
            for character in pinyin {
                if character.isNumber {
                    acronym.append(character)
                }
            }
            let letters = pinyin.toLetters()
            
            // Append the first character of the pinyin if it's a letter
            if let firstLetter = letters.first, firstLetter.isLetter {
                acronym.append(firstLetter)
            }
        }
        
        // Return the acronym
        return acronym.lowercased()
    }
    
    var alphaNumeric: String {
            return self.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "", options: [.regularExpression])
        }
    
    func toLetters() -> String {
            return self.replacingOccurrences(of: "[^A-Za-z]+", with: "", options: [.regularExpression])
        }
}
