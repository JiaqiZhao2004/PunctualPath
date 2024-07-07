//
//  Timetable.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/25/24.
//

import Foundation
import Kanna

func safeTime(seconds: Int) -> Int {
    return seconds - 40
}

func hmsToSec(h: Int, m: Int, s: Int) -> Int {
    return h * 3600 + m * 60 + s
}

func secToHms(seconds: Int) -> (Int, Int, Int) {
    let h = seconds / 3600
    var remainder = seconds % 3600
    let m = remainder / 60
    remainder = remainder % 60
    let s = remainder
    return (h, m, s)
}

func getCurrentTime() -> (Int, Int, Int)? {
    let date = Date()
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    let second = calendar.component(.second, from: date)
    return (hour, minute, second)
}

class Row: CustomStringConvertible {
    var hour: Int
    var minutes: [Int] = []

    init(hour: Int) {
        self.hour = hour
    }

    var description: String {
        let formattedMinutes = minutes.map { String(format: "%02d", $0) }.joined(separator: " ")
        return "\(hour)\t\(formattedMinutes)"
    }
}

class TimeTable: CustomStringConvertible {
    var rows: [Row] = []

    func addRow(_ row: Row) {
        rows.append(row)
    }

    var description: String {
        return "Timetable:\n" + rows.map { $0.description }.joined(separator: "\n")
    }

    func toList() -> [Int] {
        var schedule: [Int] = []
        for row in rows {
            for minute in row.minutes {
                schedule.append(hmsToSec(h: row.hour, m: minute, s: 0))
            }
        }
        return schedule
    }

    func nextTrain(h: Int? = nil, m: Int? = nil, s: Int = 0) -> String {
        var currentHour: Int
        var currentMinute: Int
        var currentSecond: Int

        if let h = h, let m = m {
            currentHour = h
            currentMinute = m
            currentSecond = s
        } else {
            guard let (hour, minute, second) = getCurrentTime() else {
                return "Error getting current time"
            }
            currentHour = hour
            currentMinute = minute
            currentSecond = second
        }

        let nowSec = hmsToSec(h: currentHour, m: currentMinute, s: currentSecond)
        let schedule = toList()
        var nextTrain: (Int, Int, Int)?
        var next2ndTrain: (Int, Int, Int)?

        for (i, timestamp) in schedule.enumerated() {
            if nowSec < safeTime(seconds: timestamp) {
                nextTrain = secToHms(seconds: safeTime(seconds: timestamp) - nowSec)
                if i == schedule.count - 1 {
                    next2ndTrain = secToHms(seconds: safeTime(seconds: schedule[0]) - nowSec)
                } else {
                    next2ndTrain = secToHms(seconds: safeTime(seconds: schedule[i + 1]) - nowSec)
                }
                break
            }
        }

        if let nextTrain = nextTrain, let next2ndTrain = next2ndTrain {
            return "\r\(nextTrain.1):\(nextTrain.2), \(next2ndTrain.1):\(next2ndTrain.2)"
        } else {
            return "No more trains"
        }
    }
}


func getStationTimetablesUrl(stationUrl: String, rootPath: String = "https://www.bjsubway.com") -> [String] {
    guard let url = URL(string: rootPath + stationUrl) else {
        print("Invalid URL: \(rootPath + stationUrl)")
        return []
    }
    
    do {
        let htmlData = try Data(contentsOf: url)
        
        // Convert data to string, trying different encodings if needed
        var htmlString: String?
        
        
        if let decodedHtmlString = String(data: htmlData, encoding: .gbk) {
            htmlString = decodedHtmlString
        }
//        print(htmlString ?? "None")
        
        // Ensure htmlString is not nil
        guard let validHtmlString = htmlString else {
            print("Failed to decode HTML data with any encoding")
            return []
        }
        
        // Parse HTML content with Kanna
        guard let doc = try? HTML(html: validHtmlString, encoding: .utf8) else {
            print("Failed to parse HTML")
            return []
        }
        
        // Find the specific <li> element with the class "tab_con skk"
        guard let tabConElement = doc.at_xpath("//li[@class='tab_con  skk']") else {
            print("Failed to find <li> element with class 'tab_con skk'")
            return []
        }
        
        // Find all <img> elements within that <li> element
        let imageElements = tabConElement.xpath(".//img")
        
        // Extract the src attribute and construct the full URLs
        var imagesUrl: [String] = []
        for img in imageElements {
            if let src = img["src"] {
                let fullUrl = rootPath + src
                imagesUrl.append(fullUrl)
            }
        }
        return imagesUrl
        
    } catch {
        print("Error: \(error)")
        return []
    }
}

func getLines() -> BeijingSubway {
    let urlString = "https://www.bjsubway.com/station/xltcx/line1/"
    
    // Create URL from string
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        return BeijingSubway()
    }
    
    do {
        // Fetch HTML content
        let htmlData = try Data(contentsOf: url)
        
        // Convert data to string, trying different encodings if needed
        var htmlString: String?

        if let decodedHtmlString = String(data: htmlData, encoding: .gbk) {
            htmlString = decodedHtmlString
        }
        
        // Ensure htmlString is not nil
        guard let validHtmlString = htmlString else {
            print("Failed to decode HTML data with any encoding")
            return BeijingSubway()
        }
        
        // Parse HTML content with Kanna
        guard let doc = try? HTML(html: validHtmlString, encoding: .utf8) else {
            print("Failed to parse HTML")
            return BeijingSubway()
        }
        
        // Initialize BeijingSubway object
        let lines = BeijingSubway()
        
        // Find all line elements
        let lineElements = doc.xpath("//div[@class='line_name']")
        
        for lineElem in lineElements {
            // Extract line name
            let lineNativeName = lineElem.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Find stations for the current line
            var stations: [String: Station] = [:]
            var stationList: [String] = []
            
            var nextElem = lineElem.nextSibling
            
            
            while let elem = nextElem, elem.className == "station" {
                let stationNativeName = elem.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                stationList.append(stationNativeName)
                if let aElement = elem.at_xpath("a"), let stationHref = aElement["href"] {
                    let stationTimetablesUrl = getStationTimetablesUrl(stationUrl: stationHref)
                    let station = Station(nativeName: stationNativeName)
                    for url in stationTimetablesUrl {
                        station.addUrl(url)
                    }
                    stations[stationNativeName] = station
                } else {
                    let station = Station(nativeName: stationNativeName)
                    stations[stationNativeName] = station
                }
                
                nextElem = elem.nextSibling
            }
            
            lines[lineNativeName] = Line(nativeName: lineNativeName, stationList: stationList, stations: stations)
            break
        }
        
        return lines
    } catch {
        print("Error: \(error)")
        return BeijingSubway()
    }
}
