//
//  LineSearchView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/14/24.
//

import SwiftUI
import UIKit
import CoreLocation
import Combine


@MainActor
class StationSearchViewModel: ObservableObject {
    
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
    
    @Published var scheduleBook: ScheduleBook? = nil
    
    
    init() {
        self.beijingSubway = loadBeijingSubwayNoThrow()
        self.allLines = self.beijingSubway.getLines().map { $0.nativeName }
    }
    
    func selectLine(lineName: String) {
        let _: () = fetch(url: kRemoteBasePath + lineName + ".json") { data in
//            self.line = Line.fromDict(data)
            self.line = try JSONDecoder().decode(Line.self, from: data)
            self.isLineSelected = true
            print("line selected")
            self.isStationSelected = false
            self.direction = ""
            self.enteredStationName = ""
            self.enteredLineName = lineName
            self.allLineStations = self.line?.getOrderedStations().map { $0.nativeName } ?? []
        }
    }
    
    func switchDirection() {
        scheduleBook?.switchSchedules()
        direction = trainDirectionFromURL(url:scheduleBook?.getFirstSchedule()?.getURL())
    }
    
    func selectStation(stationName: String) {
        station = line?.getStation(stationName)
        isStationSelected = true
        enteredStationName = stationName
        operationTime = getOperationTime()
        scheduleBook = station?.getSchedules(lineName: "", time: operationTime)
        direction = trainDirectionFromURL(url:scheduleBook?.getFirstSchedule()?.getURL())
    }
}


struct StationSearchView: View {
    
    @StateObject private var viewModel = StationSearchViewModel()
    
    @State var isTimerOn: Bool = false
    @FocusState var isTextFieldFocused: Bool
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            ZStack {
                NormalText(text: "北京地铁")
                    .padding(.trailing, 280)
                    .padding(.bottom, 90)
                    
                TextField("1号线", text: $viewModel.enteredLineName, onEditingChanged: { _ in
                    viewModel.isLineSelected = false
                    if !viewModel.isLineSelected {
                        if viewModel.enteredLineName.isEmpty {
                            viewModel.filteredLines = viewModel.allLines
                        } else {
                            viewModel.filteredLines = viewModel.allLines.filter { $0.contains(viewModel.enteredLineName) || $0.toPinyin().alphaNumeric.contains(viewModel.enteredLineName) ||
                                $0.toPinyinAcronym().contains(viewModel.enteredLineName)
                            }
                        }
                    }
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
            .onTapGesture {
                isTextFieldFocused = false
            }
            
            if !viewModel.isLineSelected {
                if viewModel.filteredLines.isEmpty && !viewModel.enteredLineName.isEmpty {
                    Text("No lines found")
                        .foregroundColor(.gray)
                } else if !viewModel.filteredLines.isEmpty {
                    List {
                        ForEach(viewModel.filteredLines, id: \.self) { line in
                            Button(action: {
                                viewModel.selectLine(lineName: line)
                                isTextFieldFocused = false
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
                    viewModel.isStationSelected = false
                    if !viewModel.isStationSelected {
                        if viewModel.enteredStationName.isEmpty {
                            viewModel.filteredStations = viewModel.allLineStations
                        } else {
                            viewModel.filteredStations = viewModel.allLineStations.filter { $0.contains(viewModel.enteredStationName) || $0.toPinyin().alphaNumeric.contains(viewModel.enteredStationName) ||
                                $0.toPinyinAcronym().contains(viewModel.enteredStationName)
                            }
                        }
                    }
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
                                    isTextFieldFocused = false
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
                    if let url = viewModel.scheduleBook?.getFirstSchedule()?.getURL() {
                        UIApplication.shared.open(URL(string: url)!)
                    }
                } label: {
                    NormalText(text: "列车时刻表原图")
                }
            }
            
        }
        .navigationTitle("地铁准时宝")
    }
    
    
}


#Preview {
    NavigationStack {
        StationSearchView()
    }
}
