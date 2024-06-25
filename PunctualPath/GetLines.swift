//
//  GetLines.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/20/24.
//

import Foundation

func fetchData(url: String) -> Data? {
    guard let url = URL(string: url) else {
        print("Invalid URL")
        return nil
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    var result: Data? = nil
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                print(error.localizedDescription)
            }
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            DispatchQueue.main.async {
                print("Invalid response from server")
            }
            return
        }
        
        guard let data = data else {
            DispatchQueue.main.async {
                print("No data received")
            }
            return
        }
        result = data
    }
    task.resume()
    return result
}


class TimetableURL {
    var direction1URL: String
    var direction2URL: String
    var url: String
    var errorMessage: String = ""

    init(direction1URL: String, direction2URL: String = "") {
        self.direction1URL = direction1URL
        self.direction2URL = direction2URL
        self.url = direction1URL
    }

    var description: String {
        return "\(url)"
    }

    func switchURL() -> TimetableURL {
        if direction2URL.isEmpty {
            return self
        }
        if url == direction1URL {
            url = direction2URL
        } else {
            url = direction1URL
        }
        return self
    }
    
    
    
    func getImg() throws {
        print("Getting image from \(url)")
        guard let data: Data = fetchData(url: url) else {
            throw URLError(.badServerResponse)
        }
    }
}

class Station {
    var nativeName: String
    var weekdayTB: [String]
    var weekendTB: [String]

    init(nativeName: String) {
        self.nativeName = nativeName
        self.weekdayTB = []
        self.weekendTB = []
    }

    var description: String {
        return nativeName
    }

    func addTimetable(timetableURL: String) {
        if timetableURL.contains("工作日") {
            weekdayTB.append(timetableURL)
        } else {
            weekendTB.append(timetableURL)
        }
    }

    func getTB(time: OperationTime) throws -> TimetableURL {
        switch time {
        case .weekday:
            if weekdayTB.count == 1 {
                return TimetableURL(direction1URL: weekdayTB[0])
            }
            return TimetableURL(direction1URL: weekdayTB[0], direction2URL: weekdayTB[1])
        case .weekend:
            if weekendTB.count == 1 {
                return TimetableURL(direction1URL: weekendTB[0])
            }
            return TimetableURL(direction1URL: weekendTB[0], direction2URL: weekendTB[1])
        }
    }
}

enum OperationTime {
    case weekday
    case weekend
}

class Line {
    var nativeName: String
    var stations: [String: Station]

    init(nativeName: String, stations: [String: Station]) {
        self.nativeName = nativeName
        self.stations = stations
        assert(stations.count >= 2)
    }

    var description: String {
        return "Line(nativeName: \(nativeName), stations: \(stations.map { $0.value.description }))"
    }

    func getStation(station: String) -> Station? {
        return stations[station]
    }
}

func getStationTimetablesURL(stationURL: String, rootPath: String = "https://www.bjsubway.com") -> [String] {
    var imagesURL: [String] = []
    // Implement network request to fetch URLs
    return imagesURL
}

func getLines() -> [String: Line] {
    let url = "https://www.bjsubway.com/station/xltcx/line1/"
    var lines: [String: Line] = [:]
    
    // Implement network request and HTML parsing to fetch lines and stations
    
    return lines
}
