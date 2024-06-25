//
//  SupportedLines.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/14/24.
//

import Foundation


struct SubwayLine {
    let nativeName: String
    let englishName: String
    let firstDirection: String
    let secondDirection: String
}

let subwayLines: [SubwayLine] = [
    SubwayLine(nativeName: "1号线", englishName: "Line 1", firstDirection: "苹果园-环球度假区", secondDirection: "环球度假区-苹果园"),
    SubwayLine(nativeName: "123", englishName: "Line 1", firstDirection: "苹果园-环球度假区", secondDirection: "环球度假区-苹果园"),
]
