//
//  LocationView.swift
//  PunctualPath
//
//  Created by Roy Zhao on 8/10/24.
//

import SwiftUI
import CoreLocation
import Combine
import Foundation

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


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published private var location: CLLocation?
    @Published private var nearestStation: String = ""
    private var locationManager: CLLocationManager
    private var stationLocations: [String: Location]
    private var timerPublisher: AnyCancellable?
    
    override init() {
        self.stationLocations = getStationLocations()
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        self.setupTimer()
    }

    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            self.location = locations.last
        }
    }
    
    private func setupTimer() {
        timerPublisher = Timer.publish(every: 5.0, on: .main, in: .default)
            .autoconnect() // Automatically connect to the timer publisher
            .receive(on: DispatchQueue.main) // Ensure updates are received on the main thread
            .sink { [weak self] _ in
                // Update your published property on the main thread
                self?.performScheduledTask()
            }
    }

    private func performScheduledTask() {
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
    
    private func getNearestStation() -> String? {
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
