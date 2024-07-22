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
    
//    @Published var imageUrl: URL?
    @Published var direction = ""
    @Published var isFirstDirection = true
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
    @Published var isImgAvailable: Bool = false
    @Published var image: UIImage? = nil
    
    
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
//        updateImgUrl()
    }
    
    func selectLine(lineName: String) {
        line = beijingSubway.getLine(lineName)
        isLineSelected = true
        isStationSelected = false
        direction = ""
        enteredStationName = ""
        enteredLineName = lineName
        allLineStations = line?.getOrderedStations().map { $0.nativeName } ?? []
    }
    
    func selectStation(stationName: String) {
        station = line?.getStation(stationName)
        isStationSelected = true
        enteredStationName = stationName
        operationTime = getOperationTime()
        timeTableUrl = station?.getTbUrls(for: operationTime)
        direction = imageUrlToDirection(url:timeTableUrl?.urls.first)
    }
    
//    func updateImgUrl() {
//        guard let url: String = timeTableUrl?.urls.first else {
//            imageUrl = nil
//            return
//        }
//        imageUrl = URL(string: url)
//    }
//    func getImg() {
//        guard let url = timeTableUrl else {
//            return
//        }
//        isImgAvailable = false
//        Task {
//            guard let image = await url.getImg() else {
//                print("Failed to fetch image.")
//                return
//            }
//            self.image = image
//            print("Fetched image successfully.")
//            isImgAvailable = true
//        }
//    }
    
    func search() {
//        getImg()
        // Example usage:
//        if let image = self.image {
//            recognizeText(from: image) { recognizedStrings in
//                print("Recognized strings: \(recognizedStrings)")
//            }
//        }
    }
    
    func getURLs(path: String) {
        // Fetch lines using your function
        let lines: BeijingSubway = getLines()
        
        let linesDict = lines.toDict()

        // Get the URL for the Documents directory
        let fileURL = NSURL(fileURLWithPath: path) as URL
        
        do {
            // Convert the dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: linesDict, options: .prettyPrinted)
            
            // Write JSON data to file
            try jsonData.write(to: fileURL)
            
            print("JSON data has been written to \(fileURL.path)")
        } catch {
            print("Error writing JSON data: \(error)")
        }
    }


}

func loadBeijingSubwayNoThrow() -> BeijingSubway {
    let URLsPath = "/Users/royzhao/Library/CloudStorage/OneDrive-UniversityofIllinois-Urbana/Coding/PunctualPath/PunctualPath/urls.json"
//        getURLs(path: URLsPath)
    return BeijingSubway.fromJsonFile(URLsPath)!
}

struct LineSearchView: View {
    
    @StateObject private var viewModel = LineSearchViewModel()
    @State var isImgDownloadViewPresented: Bool = false
    
    
    var body: some View {
        
        VStack {
            
            // first textfield
            TextField("地铁/公交线路", text: $viewModel.enteredLineName, onEditingChanged: { _ in
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
            //                .disabled(viewModel.isLineSelected)
            .autocapitalization(.none)
            .padding()
            .background(viewModel.isLineSelected ? Color.gray : Color.gray.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()
            .autocorrectionDisabled()
            
            if !viewModel.isLineSelected {
                if viewModel.filteredLines.isEmpty {
                    Text("No lines found")
                        .foregroundColor(.gray)
                } else if !viewModel.filteredLines.isEmpty {
                    List {
                        ForEach(viewModel.filteredLines, id: \.self) { line in
                            Button(action: {
                                viewModel.selectLine(lineName: line)
                            }) {
                                Text(line)
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
                //                    .disabled(viewModel.isStationSelected)
                .autocapitalization(.none)
                .padding()
                .background(viewModel.isStationSelected ? Color.gray : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .autocorrectionDisabled()
                
                if !viewModel.isStationSelected {
                    if viewModel.filteredStations.isEmpty {
                        Text("No stations found")
                            .foregroundColor(.gray)
                    } else if !viewModel.filteredStations.isEmpty {
                        List {
                            ForEach(viewModel.filteredStations, id: \.self) { station in
                                Button(action: {
                                    viewModel.selectStation(stationName: station)
                                }) {
                                    Text(station)
                                }
                            }
                        }.listStyle(.plain)
                    }
                }
            }
            
            Text("方向：\(viewModel.direction)")
            
            Button(action: { viewModel.switchDirection() }) {
                Text("切换方向")
                    .foregroundColor(.blue)
                    .frame(width: 70)
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button(action: {
                // Perform search or action
//                viewModel.search()
                if viewModel.timeTableUrl != nil {
                    isImgDownloadViewPresented = true
                }
            }) {
                Text("查询")
                    .foregroundColor(.white)
                    .bold()
                    .frame(width: 70)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Text(viewModel.timeTableUrl?.urls.first ?? "")
            
            
        }
        .navigationTitle("线路搜索")
        .sheet(isPresented: $isImgDownloadViewPresented) {
            if let url = viewModel.timeTableUrl {
                ImageDownloadView(url: url, isImgDownloadViewPresented: $isImgDownloadViewPresented)
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
