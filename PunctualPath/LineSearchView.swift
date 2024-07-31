//
//  LineSearchView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/14/24.
//

import SwiftUI
import UIKit


@MainActor
class LineSearchViewModel: ObservableObject {
    
    var beijingSubway: BeijingSubway
    
    @Published var direction = ""
    @Published var operationTime: OperationTime = OperationTime.weekday
    
    @Published var enteredLineName = ""
    var allLines: [String] = []
    @Published var filteredLines: [String] = []
    @Published var isLineSelected = false
    @Published var line: Line? = nil
    
    @Published var enteredStationName = ""
    var allLineStations: [String] = []
    @Published var isStationSelected = false
    @Published var filteredStations: [String] = []
    @Published var station: Station? = nil
    
    @Published var timeTableUrl: TimetableURL? = nil

    
    init() {
        self.beijingSubway = loadBeijingSubwayNoThrow()
        self.allLines = self.beijingSubway.getLines().map { $0.nativeName }
    }
    
    func getOperationTime() -> OperationTime {
        let currentDate = Date()

        // Get the current calendar
        let calendar = Calendar.current

        // Get the components of the current date
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: currentDate)
        
        let weekday: Int = components.weekday ?? 1
        
        // Get the name of the weekday
        let weekdaySymbols = calendar.weekdaySymbols
        let weekdayName = weekdaySymbols[weekday - 1]
        if (weekdayName == "Saturday" || weekdayName == "Sunday") {
            return OperationTime.weekend
        }
        return OperationTime.weekday
    }
    
    func imageUrlToDirection(url: String?) -> String {
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
    
    func switchDirection() {
        timeTableUrl?.switchURLs()
        direction = imageUrlToDirection(url:timeTableUrl?.urls.first)
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
                    print("Invalid response")
                    return
                }
                try completion(data)
            } catch {
                print("Download error: \(error.localizedDescription)")
                return
            }
        }
    }
    
    func selectLine(lineName: String) {
        let basePath = "https://jiaqizhao2004.github.io/PunctualPath/api/"
        let _: () = fetch(url: basePath + lineName + ".json") { data in
            self.line = try JSONDecoder().decode(Line.self, from: data)
            self.isLineSelected = true
            self.isStationSelected = false
            self.direction = ""
            self.enteredStationName = ""
            self.enteredLineName = lineName
            self.allLineStations = self.line?.getOrderedStations().map { $0.nativeName } ?? []
        }
    }
    
    func selectStation(stationName: String) {
        station = line?.getStation(stationName)
        isStationSelected = true
        enteredStationName = stationName
        operationTime = getOperationTime()
        timeTableUrl = station?.getTbUrls(for: operationTime)
        direction = imageUrlToDirection(url:timeTableUrl?.urls.first)
    }
    
    func currentTimeInSec() -> Int {
        let date = Date()
        let calendar = Calendar.current
        
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let s = calendar.component(.second, from: date)
        
        return h * 3600 + m * 60 + s
    }
    
    func nextTrain() -> Int {
        guard let station = station else {
            return 0
        }
        
        var arrivalTimes: [Int]
        
        if operationTime == OperationTime.weekday {
            arrivalTimes = station.weekdayArrivialTimes.sorted()
        } else {
            arrivalTimes = station.weekendArrivialTimes.sorted()
        }
        
        let now = currentTimeInSec()
        
        var arrivalTime = 0
        var index = 0
        
        while arrivalTime <= now {
            arrivalTime = arrivalTimes[index]
            index += 1
        }
        return arrivalTime
    }
    
}

func secondsToHoursMinutesSeconds(_ seconds: Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

func loadBeijingSubwayNoThrow() -> BeijingSubway {
    return BeijingSubway.fromJsonFile()!
}

struct LineSearchView: View {
    
    @StateObject private var viewModel = LineSearchViewModel()
    @State var isTimerOn: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            ZStack {
                NormalText(text: "北京地铁")
                    .padding(.trailing, 280)
                    .padding(.bottom, 90)
                    
                TextField("1号线", text: $viewModel.enteredLineName, onEditingChanged: { _ in
                    if !viewModel.isLineSelected {
                        if viewModel.enteredLineName.isEmpty {
                            viewModel.filteredLines = viewModel.allLines
                        } else {
                            viewModel.filteredLines = viewModel.allLines.filter { $0.contains(viewModel.enteredLineName) || $0.toPinyin().alphaNumeric.contains(viewModel.enteredLineName) ||
                                $0.toPinyinAcronym().contains(viewModel.enteredLineName)
                            }
                        }
                    }
                    viewModel.isLineSelected = false
                })
                .focused($isTextFieldFocused)
                .autocapitalization(.none)
                .padding()
                .background(viewModel.isLineSelected ? Color.gray : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .autocorrectionDisabled()
                .font(.system(size: 17))
            }
            .padding(.top, 20)
            
            if !viewModel.isLineSelected {
                if viewModel.filteredLines.isEmpty && !viewModel.enteredLineName.isEmpty {
                    Text("No lines found")
                        .foregroundColor(.gray)
                } else if !viewModel.filteredLines.isEmpty {
                    List {
                        ForEach(viewModel.filteredLines, id: \.self) { line in
                            Button(action: {
                                viewModel.selectLine(lineName: line)
                            }) {
                                Text(line)
                                    .font(.system(size: 17))
                            }
                        }
                    }.listStyle(.plain)
                }
            }
            
            if viewModel.isLineSelected {
                // second textfield
                TextField("站名", text: $viewModel.enteredStationName, onEditingChanged: { _ in
                    if !viewModel.isStationSelected {
                        if viewModel.enteredStationName.isEmpty {
                            viewModel.filteredStations = viewModel.allLineStations
                        } else {
                            viewModel.filteredStations = viewModel.allLineStations.filter { $0.contains(viewModel.enteredStationName) || $0.toPinyin().alphaNumeric.contains(viewModel.enteredStationName) ||
                                $0.toPinyinAcronym().contains(viewModel.enteredStationName)
                            }
                        }
                    }
                    viewModel.isStationSelected = false
                })
                .focused($isTextFieldFocused)
                .autocapitalization(.none)
                .padding()
                .background(viewModel.isStationSelected ? Color.gray : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .autocorrectionDisabled()
                .font(.system(size: 17))
                
                if !viewModel.isStationSelected {
                    if viewModel.filteredStations.isEmpty && !viewModel.enteredStationName.isEmpty {
                        Text("No stations found")
                            .foregroundColor(.gray)
                    } else if !viewModel.filteredStations.isEmpty {
                        List {
                            ForEach(viewModel.filteredStations, id: \.self) { station in
                                Button(action: {
                                    viewModel.selectStation(stationName: station)
                                }) {
                                    Text(station)
                                        .font(.system(size: 17))
                                }
                            }
                        }.listStyle(.plain)
                    }
                }
            }
            
            if !isTextFieldFocused {
                Text("方向：\(viewModel.direction)")
                    .font(.system(size: 17))
                    .bold()
                
                Button(action: { viewModel.switchDirection() }) {
                    Text("切换方向")
                        .foregroundColor(.black)
                        .font(.system(size: 17))
                        .frame(width: 70)
                        .bold()
                        .padding()
                        .background(Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.vertical, 10)
                }
                
                Button(action: {
                    // Perform search or action
                    //                viewModel.search()
                    if viewModel.station != nil {
                        isTimerOn = true
                    }
                    
                }) {
                    Text("查询")
                        .foregroundColor(.white)
                        .font(.system(size: 17))
                        .bold()
                        .frame(width: 70)
                        .padding()
                        .background(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button {
                    if let url = viewModel.timeTableUrl?.urls.first {
                        UIApplication.shared.open(URL(string: url)!)
                    }
                } label: {
                    NormalText(text: "列车时刻表原图")
                }
            }
            
        }
        .navigationTitle("地铁准时宝")
        .sheet(isPresented: $isTimerOn) {
            if let station = viewModel.station {
                TimerView(isTimerOn: $isTimerOn, nextTrain: secondsToHoursMinutesSeconds(viewModel.nextTrain()), stationName: station.nativeName, timeRemaining: viewModel.nextTrain() - viewModel.currentTimeInSec())
            }
        }
        
    }
}


#Preview {
    NavigationStack {
        LineSearchView()
    }
}


extension String.Encoding{
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
