//
//  ContentView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 6/10/24.
//

import SwiftUI

struct TimerView: View {
    
    @State private var timeRemaining = 100
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            VStack {
//                LineSearchView()
                Text("Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.75))
                    .clipShape(.capsule)
            }
            
        }.onReceive(timer) { time in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
}

#Preview {
    TimerView()
}
