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


class ScheduleBook {
    let stationName: String
    var schedules: [Schedule] = []
    
    init(stationName: String, schedules: [Schedule]) {
        self.stationName = stationName
        self.schedules = schedules
    }
    
    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
    }

    func switchSchedules() {
        guard !schedules.isEmpty else { return }
        schedules.append(schedules.removeFirst())
    }
    
    func firstScheduleURL() -> String {
        return schedules.first?.url ?? ""
    }
    
    func firstScheduleArrivalTimes() -> [Int] {
        return schedules.first?.arrivalTimes.sorted() ?? []
    }
    
    func firstScheduleNextTrain(at: Int = getCurrentTimeInSec()) -> Int {
        let arrivalTimes = firstScheduleArrivalTimes()
        var arrivalTime = 0
        var index = 0
        
        while arrivalTime <= at {
            if index == arrivalTimes.count {
                return -1
            }
            arrivalTime = arrivalTimes[index]
            index += 1
        }
        return arrivalTime
    }

    func printURLs() {
        for schedule in schedules {
            print(schedule.url)
        }
    }
    

    func getImg(completion: @escaping (UIImage?) -> Void) {
        guard !schedules.isEmpty else {
            completion(nil)
            return
        }
        print("Getting image from \(schedules[0])")
        guard let url = URL(string: schedules[0].url) else {
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
        guard !schedules.isEmpty else {
            return nil
        }
        print("Getting image from \(schedules[0])")
        guard let url = URL(string: schedules[0].url) else {
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

class Schedule: CustomStringConvertible, Decodable {
    var url: String
    var arrivalTimes: [Int]
    
    init(url: String, arrivalTimes: [Int]) {
        self.url = url
        self.arrivalTimes = arrivalTimes
        
        // for trains after 12 a.m.
        for (index, value) in self.arrivalTimes.enumerated() {
            if value < 3600 {
                self.arrivalTimes[index] += 86400
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case url = "url"
        case arrivalTimes = "arrival_times"
    }
    
    required init(from decoder: Decoder, debug: Bool=true) throws {
        if debug {print("Decode Schedule")}
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(String.self, forKey: .url)
        if debug {print(url)}
        arrivalTimes = try container.decode([Int].self, forKey: .arrivalTimes)
        if debug {print(arrivalTimes[0])}
        
        // for trains after 12 a.m.
        for (index, value) in arrivalTimes.enumerated() {
            if value < 3600 {
                arrivalTimes[index] += 86400
            }
        }
    }
    
//    func setArrivalTimes(arrivalTimes: [Int]) -> Void {
//        self.arrivalTimes = arrivalTimes
//    }
    
    var description: String {
        return url
    }
    
//    func addUrl(timetableUrl: String) -> OperationTime? {
//        self.url = timetableUrl
//        if timetableUrl.contains("工作日") {
//            return .weekday
//        }
//        if timetableUrl.contains("双休日") {
//            return .weekend
//        }
//        if !timetableUrl.contains("工作日") && !timetableUrl.contains("双休日") {
//            return nil
//        }
//        return nil
//    }
    
    static func fromDict(_ data: [String: Any]) -> Schedule {
        var arrivalTimes: [Int] = []
        if let arrivalTimesData = data["arrival_times"] as? [Int] {
            arrivalTimes = arrivalTimesData
        }
        return Schedule(url: data["url"] as! String, arrivalTimes: arrivalTimes)
    }
}


class Station: CustomStringConvertible, Decodable {
    var nativeName: String
    var weekdaySchedules: [Schedule]
    var weekendSchedules: [Schedule]
    var unknownSchedules: [Schedule]
    
    init(nativeName: String, weekdaySchedules: [Schedule], weekendSchedules: [Schedule], unknownSchedules: [Schedule]) {
        self.nativeName = nativeName
        self.weekdaySchedules = weekdaySchedules
        self.weekendSchedules = weekendSchedules
        self.unknownSchedules = unknownSchedules
    }
    
    required init(from decoder: Decoder, debug: Bool=true) throws {
        if debug {print("Station Decode")}
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nativeName = try container.decode(String.self, forKey: .nativeName)
        weekdaySchedules = try container.decode([Schedule].self, forKey: .weekdaySchedules)
        weekendSchedules = try container.decode([Schedule].self, forKey: .weekendSchedules)
        unknownSchedules = try container.decode([Schedule].self, forKey: .unknownSchedules)
    }

    var description: String {
        return nativeName
    }
    
    func addSchedule(schedule: Schedule, operationTime: OperationTime?) -> Void {
        guard let operationTime = operationTime else {
            unknownSchedules.append(schedule)
            return
        }
        switch operationTime {
        case OperationTime.weekday:
            weekdaySchedules.append(schedule)
        case OperationTime.weekend:
            weekendSchedules.append(schedule)
        }
    }
    
    func getSchedules(time: OperationTime) -> ScheduleBook {
        var schedules: [Schedule] = []
        if time == .weekday {
            schedules = weekdaySchedules
        }
        else if time == .weekend {
            schedules = weekendSchedules
        }
        if schedules.isEmpty {
            schedules = unknownSchedules
        }
        return ScheduleBook(stationName: nativeName, schedules: schedules)
    }
    

    static func fromDict(_ data: [String: Any]) -> Station {
        let station = Station(nativeName: data["native_name"] as! String, weekdaySchedules: [], weekendSchedules: [], unknownSchedules: [])
        for schedule in data["weekday_schedules"] as! [[String: Any]] {
            station.addSchedule(schedule: Schedule.fromDict(schedule), operationTime: .weekday)
        }
        for schedule in data["weekend_schedules"] as! [[String: Any]] {
            station.addSchedule(schedule: Schedule.fromDict(schedule), operationTime: .weekend)
        }
        for schedule in data["unknown_schedules"] as! [[String: Any]] {
            station.addSchedule(schedule: Schedule.fromDict(schedule), operationTime: nil)
        }
        return station
    }
    
    enum CodingKeys: String, CodingKey {
        case nativeName = "native_name"
        case weekdaySchedules = "weekday_schedules"
        case weekendSchedules = "weekend_schedules"
        case unknownSchedules = "unknown_schedules"
    }
}


class Line: CustomStringConvertible, Decodable {
    let nativeName: String
    let stationList: [String]
    let stations: [String: Station]
    
    required init(from decoder: Decoder, debug: Bool=true) throws {
        if debug {print("Line Decode")}
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nativeName = try container.decode(String.self, forKey: .nativeName)
        stationList = try container.decode([String].self, forKey: .stationList)
        stations = try container.decode([String: Station].self, forKey: .stations)
    }

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
    
    enum CodingKeys: String, CodingKey {
        case nativeName = "native_name"
        case stationList = "station_list"
        case stations = "stations"
    }
}


class BeijingSubway: Decodable, ObservableObject {
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
    
    func getStationScheduleBooks(name: String) -> [ScheduleBook] {
        var scheduleBooks: [ScheduleBook] = []
        for (lineName, line) in lines {
            for stationName in line.stationList {
                if stationName == name {
                    if let station = line.stations[stationName] {
                        let scheduleBook: ScheduleBook = station.getSchedules(time: getOperationTime())
                        scheduleBooks.append(scheduleBook)
                    }
                }
            }
        }
        return scheduleBooks
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
    

    static func fromJsonFile() -> BeijingSubway? {
        guard let textFileUrl = Bundle.main.url(forResource: "urls", withExtension: "json") else {
            return nil
        }
        guard let contents = try? Data(contentsOf: textFileUrl) else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: contents, options: []) as? [String: Any] else {
            return nil
        }
        
        return fromDict(json)
    }
}

func loadBeijingSubwayNoThrow() -> BeijingSubway {
    return BeijingSubway.fromJsonFile()!
}
