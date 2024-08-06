//
//  ContentView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/10/24.
//

import SwiftUI

struct TimerView: View {
    
    @Binding var isTimerOn: Bool
    @Binding var stationSchedule: StationSchedule?
    let nextTrain: (Int, Int, Int)
    let stationName: String
    @State var plentyTime: Bool = false
    @State var doorOpenTime: Bool = false
    @State var departTime: Bool = false
    
    @State var countdownSecMode: Bool = true
    
    @State var timeRemaining: Int
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    func plentyTimeToggle() {
        plentyTime.toggle()
        if plentyTime == true {
            doorOpenTime = false
            departTime = false
        }
    }
    
    func doorOpenTimeToggle() {
        doorOpenTime.toggle()
        if doorOpenTime == true {
            plentyTime = false
            departTime = false
        }
    }
    
    func departTimeToggle() {
        departTime.toggle()
        if departTime == true {
            plentyTime = false
            doorOpenTime = false
        }
    }
    
    func countdownTime() -> Int {
        return max(plentyTime ? (timeRemaining - 60) : (doorOpenTime ? (timeRemaining - 40) : timeRemaining), 0)
    }
    
    func secToHMS(seconds: Int) -> (Int, Int, Int) {
        let h = seconds / 3600
        var remainder = seconds % 3600
        let m = remainder / 60
        remainder = remainder % 60
        let s = remainder
        return (h, m, s)
    }
    
    enum TimeMode {
        case Auto
        case HMS
        case HM
        case MS
    }
    
    func HMSToString(time: (Int, Int, Int), mode: TimeMode = .Auto) -> String {
        let (h, m, s) = time
        switch mode {
        case .Auto:
            if h == 0 {
                return "\(m.toTwoDigitString()):\(s.toTwoDigitString())"
            } else {
                return "\(h.toTwoDigitString()):\(m.toTwoDigitString()):\(s.toTwoDigitString())"
            }
        case .HM:
            return "\(h.toTwoDigitString()):\(m.toTwoDigitString())"
        case .HMS:
            return "\(h.toTwoDigitString()):\(m.toTwoDigitString()):\(s.toTwoDigitString())"
        case .MS:
            return "\(m.toTwoDigitString()):\(s.toTwoDigitString())"
        }
        
    }
    
    var body: some View {
        ZStack {
            HStack {
                VStack {
                    NormalText(text: "-60s")
                        .offset(x: 0, y: 10)
                    Button {
                        if plentyTime == false {
                            plentyTimeToggle()
                        }
                    } label: {
                        ToggleButton(text: "充足时间", on: plentyTime)
                    }
                    NormalText(text: "\(max(0, timeRemaining - 60))s")
                        .offset(x: 0, y: -5)
                }
                VStack {
                    NormalText(text: "-40s")
                        .offset(x: 0, y: 10)
                    Button {
                        if doorOpenTime == false {
                            doorOpenTimeToggle()
                        }
                    } label: {
                        ToggleButton(text: "到站时间", on: doorOpenTime)
                    }
                    NormalText(text: "\(max(0, timeRemaining - 40))s")
                        .offset(x: 0, y: -5)
                }
//                VStack {
//                    NormalText(text: "-0s")
//                        .offset(x: 0, y: 10)
//                    Button {
//                        if departTime == false {
//                            departTimeToggle()
//                        }
//                    } label: {
//                        ToggleButton(text: "离站时间", on: departTime)
//                    }
//                    NormalText(text: "\(max(0, timeRemaining))s")
//                        .offset(x: 0, y: -5)
//                }
            }.offset(x: 0, y: 330)
            VStack {
                NormalText(text:"如下计划的列车")
                    .padding(.top, 55)
                CapsuleText(text: HMSToString(time: nextTrain, mode: .HM))
                NormalText(text: "将于")
                Button {
                    countdownSecMode.toggle()
                } label: {
                    CapsuleText(text: countdownSecMode ? "\(countdownTime())" : HMSToString(time: secToHMS(seconds: countdownTime())))
                }
                
                NormalText(text:"秒后到达")
                Text(stationName)
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
                    if let url = stationSchedule?.firstURL() {
                        UIApplication.shared.open(URL(string: url)!)
                    }
                } label: {
                    NormalText(text: "列车时刻表原图")
                }
            }.padding(.bottom, 90)
            
        }.onReceive(timer) { time in
            if timeRemaining > -60 {
                timeRemaining -= 1
            }
        }
        .onAppear {
            plentyTimeToggle()
        }
    }
    
    func cancel() {
        isTimerOn = false
    }
    
}

extension Int {
    func toTwoDigitString() -> String {
        if self >= 10 || self < 0 {
            return "\(self)"
        }
        return "0\(self)"
    }
}

#Preview {
    TimerView(isTimerOn: .constant(true), stationSchedule: .constant(nil), nextTrain: (00, 00, 5), stationName: "某某站", timeRemaining: 50)
}
