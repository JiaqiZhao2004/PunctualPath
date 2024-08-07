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

func hmsToSec(time: (Int, Int, Int)) -> Int {
    let (h, m, s) = time
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
                    let station = Station(nativeName: stationNativeName, weekdaySchedules: [], weekendSchedules: [], unknownSchedules: [])
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
