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
    if getSecondsSinceStartOfDay() < 3600 {
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

func getSecondsSinceStartOfDay() -> Int {
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

enum TimeDisplayMode {
    case Auto
    case HHMMSS
    case HHMM
    case MMSS
    case Seconds
}

class SimpleTime: Equatable, Comparable {
    
    private var hour: Int
    private var minute: Int
    private var second: Int
    var totalSeconds: Int {
        return hour * 3600 + minute * 60 + second
    }
    
    init(hour: Int, minute: Int, second: Int) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }
    
    init(_ secondsSinceStartOfDay: Int) {
        var seconds = secondsSinceStartOfDay
        while seconds >= 86400 {
            seconds -= 86400
        }
        self.hour = seconds / 3600
        self.minute = (seconds % 3600) / 60
        self.second = (seconds % 3600) % 60
    }
    
    init(_ simpleTime: SimpleTime) {
        self.hour = simpleTime.hour
        self.minute = simpleTime.minute
        self.second = simpleTime.second
    }
    
    func toString(mode: TimeDisplayMode = .Auto) -> String {
        switch mode {
        case .Auto:
            if hour == 0 {
                return "\(digitToTwoDigitString(minute)):\(digitToTwoDigitString(second))"
            } else {
                return "\(digitToTwoDigitString(hour)):\(digitToTwoDigitString(minute)):\(digitToTwoDigitString(second))"
            }
        case .HHMM:
            return "\(digitToTwoDigitString(hour)):\(digitToTwoDigitString(minute))"
        case .HHMMSS:
            return "\(digitToTwoDigitString(hour)):\(digitToTwoDigitString(minute)):\(digitToTwoDigitString(second))"
        case .MMSS:
            return "\(digitToTwoDigitString(minute)):\(digitToTwoDigitString(second))"
        case .Seconds:
            return "\(hour * 3600 + minute * 60 + second)s"
        }
    }
    
    // Overload the "-" operator to subtract seconds
    static func - (lhs: SimpleTime, seconds: Int) -> SimpleTime {
        let currentTotalSeconds = lhs.totalSeconds
        var newTotalSeconds = currentTotalSeconds - seconds
        
        // Ensure the result wraps around if it goes below 0.
        while newTotalSeconds < 0 {
            newTotalSeconds += 86400
        }
        
        return SimpleTime(newTotalSeconds)
    }
    
    static func + (lhs: SimpleTime, seconds: Int) -> SimpleTime {
        let currentTotalSeconds = lhs.totalSeconds
        var newTotalSeconds = currentTotalSeconds + seconds
        
        // Ensure the result wraps around if it goes below 0.
        while newTotalSeconds > 86400 {
            newTotalSeconds -= 86400
        }
        
        return SimpleTime(newTotalSeconds)
    }
    
    // Overload the "==" operator for equality comparison
    static func == (lhs: SimpleTime, rhs: SimpleTime) -> Bool {
        return lhs.totalSeconds == rhs.totalSeconds
    }
    
    // Overload the "<" operator for less than comparison
    static func < (lhs: SimpleTime, rhs: SimpleTime) -> Bool {
        return lhs.totalSeconds < rhs.totalSeconds
    }
    
    // Overload the ">" operator for greater than comparison
    static func > (lhs: SimpleTime, rhs: SimpleTime) -> Bool {
        return lhs.totalSeconds > rhs.totalSeconds
    }
    
    // Overload the "<=" operator for less than or equal to comparison
    static func <= (lhs: SimpleTime, rhs: SimpleTime) -> Bool {
        return lhs.totalSeconds <= rhs.totalSeconds
    }
    
    // Overload the ">=" operator for greater than or equal to comparison
    static func >= (lhs: SimpleTime, rhs: SimpleTime) -> Bool {
        return lhs.totalSeconds >= rhs.totalSeconds
    }
    
    private func digitToTwoDigitString(_ digit: Int) -> String {
        if digit >= 10 || digit < 0 {
            return "\(digit)"
        }
        return "0\(digit)"
    }
}
