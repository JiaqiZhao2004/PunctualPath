//
//  Backend.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/25/24.
//

import Foundation
import UIKit


enum OperationTime {
    case weekday
    case weekend
}


class TimetableURL {
    var urls: [String] = []

    func addURL(_ url: String) {
        urls.append(url)
    }

    func switchURLs() {
        guard !urls.isEmpty else { return }
        urls.append(urls.removeFirst())
    }

    func printURLs() {
        for url in urls {
            print(url)
        }
    }

    func getImg(completion: @escaping (UIImage?) -> Void) {
        guard !urls.isEmpty else {
            completion(nil)
            return
        }
        print("Getting image from \(urls[0])")
        guard let url = URL(string: urls[0]) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Download error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            let image = UIImage(data: data)
            completion(image)
        }
        task.resume()
    }

    func getImg() async -> UIImage? {
        guard !urls.isEmpty else {
            return nil
        }
        print("Getting image from \(urls[0])")
        guard let url = URL(string: urls[0]) else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response")
                return nil
            }
            let image = UIImage(data: data)
            return image
        } catch {
            print("Download error: \(error.localizedDescription)")
            return nil
        }
    }

}


class Station: CustomStringConvertible {
    var nativeName: String
    var weekdayUrls: [String] = []
    var weekendUrls: [String] = []
    var unknownUrls: [String] = []

    init(nativeName: String) {
        self.nativeName = nativeName
    }

    var description: String {
        return nativeName
    }

    func addUrl(_ timetableUrl: String) {
        if timetableUrl.contains("工作日") {
            weekdayUrls.append(timetableUrl)
        }
        if timetableUrl.contains("双休日") {
            weekendUrls.append(timetableUrl)
        }
        if !timetableUrl.contains("工作日") && !timetableUrl.contains("双休日") {
            unknownUrls.append(timetableUrl)
        }
    }

    func getTbUrls(for time: OperationTime) -> TimetableURL {
        let urls = TimetableURL()
        switch time {
        case .weekday:
            for weekdayUrl in weekdayUrls {
                urls.addURL(weekdayUrl)
            }
        case .weekend:
            for weekendUrl in weekendUrls {
                urls.addURL(weekendUrl)
            }
        }
        if urls.urls.isEmpty {
            for unknownUrl in unknownUrls {
                urls.addURL(unknownUrl)
            }
        }
        return urls
    }

    func toDict() -> [String: Any] {
        return [
            "native_name": nativeName,
            "weekday_tb": weekdayUrls,
            "weekend_tb": weekendUrls,
            "unknown_tb": unknownUrls
        ]
    }

    static func fromDict(_ data: [String: Any]) -> Station {
        let station = Station(nativeName: data["native_name"] as! String)
        station.weekdayUrls = data["weekday_tb"] as! [String]
        station.weekendUrls = data["weekend_tb"] as! [String]
        station.unknownUrls = data["unknown_tb"] as! [String]
        return station
    }
}


class Line: CustomStringConvertible {
    var nativeName: String
    var stationList: [String]
    var stations: [String: Station]

    init(nativeName: String, stationList: [String], stations: [String: Station]) {
        self.nativeName = nativeName
        self.stationList = stationList
        self.stations = stations
        assert(self.stations.count >= 2)
    }

    var description: String {
        let stationDescriptions = stations.values.map { $0.description }
        return "Line(native_name=\(nativeName), stations=\(stationDescriptions))"
    }

    func getStation(_ station: String) -> Station? {
        return stations[station]
    }
    
    func getOrderedStations() -> [Station] {
        return stationList.compactMap { stationName in
            return stations[stationName]
        }
    }

    func getStations() -> [Station] {
        return Array(stations.values)
    }

    func toDict() -> [String: Any] {
        // Convert the stations dictionary to a JSON-serializable dictionary
        var stationsDict: [String: [String: Any]] = [:]
        for (name, station) in stations {
            stationsDict[name] = station.toDict()
        }
        return [
            "native_name": nativeName,
            "station_list": stationList,
            "stations": stationsDict
        ]
    }

    static func fromDict(_ data: [String: Any]) -> Line {
        // Convert the JSON-serializable dictionary back to a dictionary of Station objects
        var stations: [String: Station] = [:]
        let stationList: [String] = data["station_list"] as! [String]
        if let stationData = data["stations"] as? [String: [String: Any]] {
            for (name, stationDict) in stationData {
                stations[name] = Station.fromDict(stationDict)
            }
        }
        return Line(nativeName: data["native_name"] as! String, stationList: stationList, stations: stations)
    }
}


class BeijingSubway {
    var name: String
    var lines: [String: Line]

    init(lines: [String: Line] = [:]) {
        self.name = "BeijingSubway"
        self.lines = lines
    }

    func getLine(_ line: String) -> Line? {
        return lines[line]
    }

    func getLines() -> [Line] {
        return Array(lines.values)
    }

    subscript(key: String) -> Line? {
        get {
            return lines[key]
        }
        set {
            lines[key] = newValue
        }
    }

    func toDict() -> [String: Any] {
        let linesDict = lines.reduce(into: [String: [String: Any]]()) { result, pair in
            result[pair.key] = pair.value.toDict()
        }
        return [
            "name": name,
            "lines": linesDict
        ]
    }

    static func fromDict(_ data: [String: Any]) -> BeijingSubway {
        var lines: [String: Line] = [:]
        if let linesData = data["lines"] as? [String: [String: Any]] {
            for (name, lineData) in linesData {
                lines[name] = Line.fromDict(lineData)
            }
        }
        return BeijingSubway(lines: lines)
    }

    static func fromJsonFile(_ filePath: String) -> BeijingSubway? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return fromDict(json)
    }
}

