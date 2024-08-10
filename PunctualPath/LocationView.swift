//
//  LocationView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/10/24.
//

import SwiftUI
import CoreLocation
import Combine

struct Location: Decodable {
    let longitude: Double
    let latitude: Double
    
    init(location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
    }
    
    func distance(to location: Location) -> Double {
        let dLon = Double(location.longitude - longitude)
        let dLat = Double(location.latitude - latitude)
        return sqrt(dLon * dLon + dLat * dLat)
    }
}


func getStationLocations() -> [String: Location] {
    // Decode the JSON from the file
    if let jsonData = loadJSONFromFile(named: "StationLocations") {
        do {
            // Decode the JSON data into a dictionary of type [String: Location]
            let stationLocations = try JSONDecoder().decode([String: Location].self, from: jsonData)
            return stationLocations
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }
    return [:]
}

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    private var locationManager: CLLocationManager
    private var timer: AnyCancellable?
    @Published var nearestStation: String = ""
    private var stationLocations: [String: Location]

    override init() {
        self.stationLocations = getStationLocations()
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        startTimer()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func startTimer() {
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performScheduledTask()
            }
    }

    func performScheduledTask() {
        // Perform your desired task here every 5 seconds.
        // For example, you might want to fetch the current location or update the UI.
        print("Performing scheduled task")
        if let location = location {
            print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            nearestStation = getNearestStation() ?? "定位失败"
        } else {
            print("Location not available")
        }
    }
    
    func getNearestStation() -> String? {
        guard let clLocation = self.location else {
            return nil
        }
        
        let location = Location(location: clLocation)
        
        guard !stationLocations.isEmpty else { return nil }
        
        var nearestStation: (name: String, distance: Double)?
        
        for (stationName, stationLocation) in stationLocations {
            let distance = stationLocation.distance(to: location)
            
            if nearestStation == nil || distance < nearestStation!.distance {
                nearestStation = (name: stationName, distance: distance)
            }
        }
        return nearestStation?.name
    }
}




struct LocationView: View {
    @StateObject private var viewModel = LocationViewModel()

    var body: some View {
        VStack {
            if let location = viewModel.location {
                Text(viewModel.nearestStation)
            } else {
                Text("Fetching location...")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationView()
    }
}

