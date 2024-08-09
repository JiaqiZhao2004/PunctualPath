//
//  TimeUtils.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/6/24.
//

import Foundation

func getDayOfWeek() -> String {
    let currentDate = Date()
    let calendar = Calendar.current

    let components = calendar.dateComponents([.year, .month, .day, .weekday], from: currentDate)
    
    var weekday: Int = components.weekday ?? 1
    
    // if time is 12am to 1am, still see it as the last day
    if getCurrentTimeInSec() < 3600 {
        if weekday == 1 {
            weekday = 7
        } else {
            weekday -= 1
        }
    }
    
    let weekdaySymbols = calendar.weekdaySymbols
    let weekdayName = weekdaySymbols[weekday - 1]
    
    return weekdayName
}

func getOperationTime() -> OperationTime {
    let weekdayName = getDayOfWeek()
    if (weekdayName == "Saturday" || weekdayName == "Sunday") {
        return OperationTime.weekend
    }
    return OperationTime.weekday
}

func getCurrentTimeInSec() -> Int {
    let date = Date()
    let calendar = Calendar.current
    
    var h = calendar.component(.hour, from: date)
    // if time is 12am to 1am, still see it as the last day
    if h < 1 {
        h += 24
    }
    let m = calendar.component(.minute, from: date)
    let s = calendar.component(.second, from: date)
    
    return h * 3600 + m * 60 + s
}

func secToHMS(_ seconds: Int) -> (Int, Int, Int) {
    var seconds = seconds
    if seconds >= 86400 {
        seconds -= 86400
    }
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

enum TimeMode {
    case Auto
    case HMS
    case HM
    case MS
}

func HMSToString(time: (Int, Int, Int), mode: TimeMode = .Auto) -> String {
    let (h, m, s) = time
    switch mode {
    case .Auto:
        if h == 0 {
            return "\(m.toTwoDigitString()):\(s.toTwoDigitString())"
        } else {
            return "\(h.toTwoDigitString()):\(m.toTwoDigitString()):\(s.toTwoDigitString())"
        }
    case .HM:
        return "\(h.toTwoDigitString()):\(m.toTwoDigitString())"
    case .HMS:
        return "\(h.toTwoDigitString()):\(m.toTwoDigitString()):\(s.toTwoDigitString())"
    case .MS:
        return "\(m.toTwoDigitString()):\(s.toTwoDigitString())"
    }
}

extension Int {
    func toTwoDigitString() -> String {
        if self >= 10 || self < 0 {
            return "\(self)"
        }
        return "0\(self)"
    }
}
