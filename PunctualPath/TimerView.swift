//
//  ContentView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/10/24.
//

import SwiftUI

struct TimerView: View {
    
    @Binding var isTimerOn: Bool
    let nextTrain: (Int, Int, Int)
    let stationName: String
    @State var plentyTime: Bool = false
    @State var doorOpenTime: Bool = false
    @State var departTime: Bool = false
    
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
                VStack {
                    NormalText(text: "-0s")
                        .offset(x: 0, y: 10)
                    Button {
                        if departTime == false {
                            departTimeToggle()
                        }
                    } label: {
                        ToggleButton(text: "离站时间", on: departTime)
                    }
                    NormalText(text: "\(max(0, timeRemaining))s")
                        .offset(x: 0, y: -5)
                }
            }.offset(x: 0, y: 330)
            VStack {
                NormalText(text:"如下计划的列车")
                    .padding(.top, 55)
                CapsuleText(text: nextTrainToString())
                NormalText(text: "将于")
                CapsuleText(text: "\(max(plentyTime ? (timeRemaining - 60) : (doorOpenTime ? (timeRemaining - 40) : timeRemaining), 0))")
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
    
    func nextTrainToString() -> String {
        let (h, m, s) = nextTrain
        let h_str = (h >= 10) ? String(h) : "0\(String(h))"
        let m_str = (m >= 10) ? String(m) : "0\(String(m))"
        let s_str = (s >= 10) ? String(s) : "0\(String(s))"
        if h == 0 {
            return "\(m_str):\(s_str)"
        }
        return "\(h_str):\(m_str):\(s_str)"
    }
}

#Preview {
    TimerView(isTimerOn: .constant(true), nextTrain: (00, 00, 00), stationName: "某某站", timeRemaining: 50)
}
