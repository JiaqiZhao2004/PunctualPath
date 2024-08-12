//
//  RootView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/10/24.
//

import SwiftUI

struct RootView: View {
    private var beijingSubway: BeijingSubway
    private var locationManager: LocationManager
    
    init() {
        self.beijingSubway = loadBeijingSubwayNoThrow()
        self.locationManager = LocationManager()
    }
    
    var body: some View {
        // Pass the object to child views as needed
        StationView()
            .environmentObject(beijingSubway)
            .environmentObject(locationManager)
    }
}

#Preview {
    RootView()
}
