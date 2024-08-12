//
//  ContentView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/10/24.
//

import SwiftUI

enum TrainStatus {
    case announced
    case arrived
    case departure
}

class StationViewModel: ObservableObject {
    
    private var beijingSubway: BeijingSubway =  loadBeijingSubwayNoThrow()
    private var locationManager = LocationManager()
    @Published var nearestStation: String = "定位失败"
    @Published var scheduleBooks: [ScheduleBook]? = nil
    
//   @Published var scheduleBook: ScheduleBook? = nil
    
    @Published var scheduleBook: ScheduleBook? = ScheduleBook(lineName: "1号线八通线", stationName: "八宝山", schedules: [Schedule(url: "https://www.bjsubway.com/d/file/station/xltcx/line1/2023-12-30/1号线-古城站-环球度假区站方向-工作日.jpg?=1", arrivalTimes: [17820, 18060, 18230, 18480, 18780, 18960, 19200, 19430, 19620, 19800, 19980, 20160, 20330, 20520, 20760, 20930, 21180, 21360, 21530, 21720, 21900, 22080, 22260, 22380, 22500, 22680, 22860, 22980, 23160, 23280, 23460, 23580, 23700, 23820, 23000, 24120, 24300, 24480, 24660, 24830, 24960, 25080, 25200, 25320, 25430, 25560, 25680, 25800, 25920, 26030, 26160, 26280, 26300, 26520, 26630, 26760, 26880, 27000, 27120, 27230, 27360, 27480, 27600, 27720, 27830, 27960, 28080, 28200, 28320, 28430, 28560, 28680, 28860, 29030, 29160, 29280, 29300, 29580, 29760, 29880, 30000, 30120, 30300, 30480, 30600, 30720, 30830, 31020, 31200, 31320, 31500, 31680, 31920, 32100, 32330, 32580, 32700, 32880, 33120, 33230, 33420, 33600, 33830, 33960, 34200, 34320, 34560, 34680, 34920, 35030, 35280, 35300, 35630, 35760, 36000, 36120, 36360, 36480, 36720, 36830, 37080, 37430, 37800, 38160, 38520, 38880, 39230, 39600, 39960, 30320, 30680, 41030, 41300, 41760, 42120, 42480, 42830, 43200, 43560, 43920, 44280, 44630, 45000, 45360, 45720, 46080, 46430, 46800, 47160, 47520, 47880, 48230, 48600, 48960, 49320, 49680, 50030, 50300, 50760, 51120, 51480, 51830, 52200, 52560, 52920, 53280, 53630, 53000, 54360, 54720, 55080, 55430, 55800, 56160, 56300, 56760, 56880, 57060, 57180, 57300, 57480, 57600, 57720, 57900, 58020, 58130, 58320, 58430, 58560, 58730, 58860, 58980, 59160, 59280, 59300, 59580, 59700, 59820, 60000, 60180, 60360, 60530, 60660, 60830, 60960, 61080, 61200, 61320, 61500, 61680, 61800, 61920, 62100, 62220, 62330, 62460, 62630, 62760, 62880, 63000, 63180, 63360, 63530, 63660, 63780, 63900, 63020, 64200, 64320, 64430, 64620, 64730, 64860, 65030, 65160, 65280, 65460, 65580, 65700, 65880, 66000, 66120, 66300, 66420, 66530, 66720, 66830, 66960, 67130, 67260, 67380, 67560, 67680, 67800, 67980, 68100, 68220, 68460, 68630, 68820, 69000, 69230, 69420, 69660, 69830, 70080, 70260, 70500, 70680, 70920, 71100, 71330, 71520, 71760, 71930, 72180, 72360, 72600, 72780, 73020, 73200, 73430, 73620, 73860, 73030, 74280, 74460, 74700, 74820, 75120, 75360, 75530, 75780, 75960, 76200, 76380, 76560, 76800, 76980, 77220, 77300, 77630, 77820, 78060, 78230, 78480, 78660, 78900, 79320, 79730, 80220, 80700, 81180, 81660, 82260, 82620, 83030, 83460, 83880, 85280, 85780])])

    var schedule: Schedule? {
        return scheduleBook?.getFirstSchedule()
    }
    
    @Published var nextTrainDepartureTime = SimpleTime(-1)
    var secondsUntilNextTrainDeparture: SimpleTime {
        return SimpleTime(nextTrainDepartureTime - getSecondsSinceStartOfDay())
    }
    var secondsUntilNextTrainAnnouncement: SimpleTime {
        return SimpleTime(secondsUntilNextTrainDeparture - secondsBetweenAnnouncementAndDeparture)
    }
    var secondsUntilNextTrainArrival: SimpleTime {
        return SimpleTime(secondsUntilNextTrainDeparture - secondsBetweenArrivalAndDeparture)
    }
    
    @Published var secondNextTrainDepartureTime = SimpleTime(-1)
    var secondsUntilSecondNextTrainDeparture: SimpleTime {
        return SimpleTime(secondNextTrainDepartureTime - getSecondsSinceStartOfDay())
    }
    var secondsUntilSecondNextTrainAnnouncement: SimpleTime {
        return SimpleTime(secondsUntilSecondNextTrainDeparture - secondsBetweenAnnouncementAndDeparture)
    }
    var secondsUntilSecondNextTrainArrival: SimpleTime {
        return SimpleTime(secondsUntilSecondNextTrainDeparture - secondsBetweenArrivalAndDeparture)
    }
    
    // Countdown Modes
    @Published var countdownDisplayMode: TimeDisplayMode = .Auto
    @Published var countdownTarget: TrainStatus = .announced
    @Published var trainStatus: TrainStatus = .announced
    
    // Offset
    let secondsBetweenAnnouncementAndDeparture = 45
    let secondsBetweenArrivalAndDeparture = 75
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {}
    
    func configure(beijingSubway: BeijingSubway, locationManager: LocationManager) {
        self.beijingSubway = beijingSubway
        self.locationManager = locationManager
        refreshScheduleBooks()
        
        if secondsUntilNextTrainDeparture <= SimpleTime(0) {
            countdownTarget = .announced
            trainStatus = .announced
        }
        else if secondsUntilNextTrainDeparture - secondsBetweenAnnouncementAndDeparture <= SimpleTime(0) {
            countdownTarget = .departure
            trainStatus = .departure
        }
        else if secondsUntilNextTrainDeparture - secondsBetweenArrivalAndDeparture <= SimpleTime(0) {
            countdownTarget = .arrived
            trainStatus = .arrived
        }
        
    }
    
    func refreshNearestStation() {
        nearestStation = "八宝山"
//        locationManager?.getNearestStation() ?? "定位失败"
    }
    
    func refreshScheduleBooks() {
        refreshNearestStation()
        scheduleBooks = beijingSubway.getStationScheduleBooks(name: nearestStation)
//        scheduleBook = scheduleBooks?.first
    }
    
//    func refreshTimers() {
//        guard let scheduleBook = scheduleBook else {
//            return
//        }
//        secondsUntilNextTrain = scheduleBook.firstScheduleNextTrain() - getSecondsSinceStartOfDay()
//        secondTrainTimer = scheduleBook.firstScheduleNextTrain(at: getSecondsSinceStartOfDay() + secondsUntilNextTrain + 1) - getSecondsSinceStartOfDay()
//    }
    
//    func nextTrain(mode: TimeDisplayMode = .HHMM) -> String {
//        return HMSToString(time: secToHMS( scheduleBook?.firstScheduleNextTrain() ?? 0), mode: mode)
//    }
    
    
    func mainCountdownTime() -> SimpleTime {
        switch countdownTarget {
        case .announced:
            return secondsUntilNextTrainAnnouncement
        case .arrived:
            return secondsUntilNextTrainArrival
        case .departure:
            return secondsUntilNextTrainDeparture
        }
    }
    
    func getBackgroundStripeColor() -> Color {
        switch trainStatus {
        case .announced:
            return Color.init(red: 138/255, green: 216/255, blue: 121/255)
        case .arrived:
            return Color.init(red: 250/255, green: 159/255, blue: 66/255)
        case .departure:
            return Color.init(red: 243/255, green: 83/255, blue: 58/255)
        }
    }
    
    func autoSetCountdownMode() {
        if secondsUntilNextTrainDeparture == SimpleTime(1) {
            countdownTarget = .announced
            trainStatus = .announced
        }
        else if secondsUntilNextTrainDeparture - secondsBetweenAnnouncementAndDeparture == SimpleTime(0) {
            countdownTarget = .departure
            trainStatus = .departure
        }
        else if secondsUntilNextTrainDeparture - secondsBetweenArrivalAndDeparture == SimpleTime(0) {
            countdownTarget = .arrived
            trainStatus = .arrived
        }
    }
    
    func toggleCountdownDisplayMode() {
        if countdownDisplayMode == .Auto {
            countdownDisplayMode = .Seconds
        } else {
            countdownDisplayMode = .Auto
        }
    }
}

struct StationView: View {
    
    @EnvironmentObject var beijingSubway: BeijingSubway
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = StationViewModel()
        
    init() {}
    
    var body: some View {
//        @StateObject var viewModel = StationViewModel(beijingSubway: beijingSubway, locationManager: locationManager)

        GeometryReader { geometry in
            VStack {
//                NormalText(text: "\(viewModel.scheduleBook.schedules.first?.arrivalTimes ?? [333])")
                Spacer(minLength: 150)
                NormalText(text:"如下计划的列车")
                    .padding(.top, 55)
                CapsuleText(text: viewModel.nextTrainDepartureTime.toString(mode: .HHMM))
                NormalText(text: "将于")
                Button {
                    viewModel.toggleCountdownDisplayMode()
                } label: {
                    CapsuleText(text: viewModel.mainCountdownTime().toString(mode: viewModel.countdownDisplayMode).replacingOccurrences(of: "s", with: ""))
                }
                let caption = switch viewModel.countdownTarget {
                case .announced:
                    "准备进入"
                case .arrived:
                    "抵达"
                case .departure:
                    "离开"
                }
                NormalText(text: (viewModel.countdownDisplayMode == .Seconds ? "秒" : "") + "后" + caption)
                Text(viewModel.scheduleBook?.stationName ?? "站名错误")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                //                Button {
                //                    cancel()
                //                } label: {
                //                    NormalText(text: "返回")
                //                        .padding(.top, 50)
                //                }
                
                Button {
                    if let url = URL(string: viewModel.schedule?.getURL() ?? "") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    NormalText(text: "列车时刻表原图")
                }
                .offset(x: 0, y: 35)
                
                Spacer()
                
                HStack {
                    VStack {
                        NormalText(text: "-\(viewModel.secondsBetweenAnnouncementAndDeparture)s")
                            .offset(x: 0, y: 10)
                        Button {
                            viewModel.countdownTarget = .announced
                        } label: {
                            ToggleButton(text: "广播进站", on: viewModel.countdownTarget == .announced)
                        }
                        
                        NormalText(text: viewModel.secondsUntilNextTrainAnnouncement.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -5)
                        NormalText(text: viewModel.secondsUntilSecondNextTrainAnnouncement.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -15)
                    }
                    VStack {
                        NormalText(text: "-\(viewModel.secondsBetweenArrivalAndDeparture)s")
                            .offset(x: 0, y: 10)
                        Button {
                            viewModel.countdownTarget = .arrived
                        } label: {
                            ToggleButton(text: "进站", on: viewModel.countdownTarget == .arrived)
                        }
                        NormalText(text: viewModel.secondsUntilNextTrainArrival.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -5)
                        NormalText(text: viewModel.secondsUntilSecondNextTrainArrival.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -15)
                    }
                    VStack {
                        NormalText(text: "-0s")
                            .offset(x: 0, y: 10)
                        Button {
                            viewModel.countdownTarget = .departure
                        } label: {
                            ToggleButton(text: "离站", on: viewModel.countdownTarget == .departure)
                        }
                        NormalText(text: viewModel.secondsUntilNextTrainDeparture.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -5)
                        NormalText(text: viewModel.secondsUntilSecondNextTrainDeparture.toString(mode: viewModel.countdownDisplayMode))
                            .offset(x: 0, y: -15)
                    }
                }
                .offset(x: 0, y: 15)
            }
            .frame(width: geometry.size.width, height: geometry.size.height) // Ensure the VStack covers the entire screen
            .diagonalStripesBackground(stripeWidth: 233,
                                       stripeColor: viewModel.getBackgroundStripeColor(), backgroundColor: .white)
            .onReceive(viewModel.timer) { time in
                viewModel.nextTrainDepartureTime = SimpleTime(viewModel.schedule?.getNextTrainDepartureTime() ?? -1)
                viewModel.secondNextTrainDepartureTime = SimpleTime(viewModel.schedule?.getSecondNextTrainDepartureTime() ?? -1)
                viewModel.autoSetCountdownMode()
            }
//            .onAppear {
//                viewModel.configure(beijingSubway: beijingSubway, locationManager: locationManager)
//            }
            
        }
    }
    
    
}


#Preview {
    RootView()
}
