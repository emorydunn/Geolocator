//
//  ReverseGeocoder.swift
//  Geolocator
//
//  Created by Emory Dunn on 12 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import CoreLocation

public protocol ReverseGeocoder {
    var showActivityCount: Int { get }
        
    func reverseGeocodeLocation(_ location: LocatableImage, complete: @escaping (_ message: String) -> Void)

}

public class AppleGeocoder: ReverseGeocoder {
    
    public let showActivityCount: Int = 100
    
    public init() {
        
    }
    
    public func reverseGeocodeLocation(_ location: LocatableImage, complete: @escaping (_ message: String) -> Void) {
        NSLog("Begin reverse geocode for \(location.displayName)")
        
        guard location.status?.bool == true else {
            complete("GPS status is false")
            return
        }
        
        let geocoder = CLGeocoder()
        let coreLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(coreLocation) { (placemarks, error) in
            guard error == nil else {
                complete(error!.localizedDescription)
                return
            }
            guard let firstLocation = placemarks?[0] else {
                complete("No location found for \(location.displayName)")
                return
            }
            
            // Assign location information
            location.country = firstLocation.country
            location.state = firstLocation.state
            location.city = firstLocation.city
//            location.route = firstLocation.route
            location.neighborhood = firstLocation.neighborhood
            
            complete("Assigning location information to \(location.displayName)")
        }
    }
    
}

public class GoogleGeocoder: ReverseGeocoder {
    
    public let showActivityCount: Int = 50
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func reverseGeocodeLocation(_ location: LocatableImage, complete: @escaping (_ message: String) -> Void) {
        NSLog("Begin reverse geocode for \(location.displayName)")
        
        guard location.status?.bool == true else {
            complete("GPS status is false")
            return
        }

        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.latitude),\(location.longitude)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            complete("Could not construct Google geocode URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let dict = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                complete("Could not read JSON object from data")
                return
            }
            
            guard let place = self.extractPlace(from: dict) else {
                complete("Could not extract place information from JSON with url \(urlString)")
                return
            }
            
            // Assign location information
            location.country = place.country
            location.state = place.state
            location.city = place.city
//            location.route = place.route
            location.neighborhood = place.neighborhood
            
            complete("Assigning location information to \(location.displayName)")

        }
        
        task.resume()

    }


    public func extractPlace(from json: [String: Any]) -> IPTCLocatable? {

        guard let results = json["results"] as? [[String: Any]], let firstResult = results.first else {
            NSLog("JSON did not contain a `results` key")
            return nil
        }

        guard let addressComponents = firstResult["address_components"] as? [[String: Any]] else {
            NSLog("First result does not contain `address_components` key")
            return nil
        }

        let places = addressComponents.compactMap { json in
            GooglePlace(fromJSONDict: json)
        }

        var location = IPTCLocation(country: nil, state: nil, city: nil, route: nil, neighborhood: nil)
        
        places.forEach { place in
            if place.types.contains("country") {
                location.country = place.longName
            } else if place.types.contains("administrative_area_level_1") {
                location.state = place.longName
            } else if place.types.contains("locality") {
                location.city = place.longName
            } else if place.types.contains("route") {
                location.route = place.longName
            } else if place.types.contains("neighborhood") {
                location.neighborhood = place.longName
            }


        }
        return location

    }

}

struct GooglePlace: Decodable {
    let longName: String
    let shortName: String
    let types: [String]
    
    enum CodingKeys: String, CodingKey {
        case longName = "long_name"
        case shortName = "short_name"
        case types
    }
    
    init?(fromJSONDict json: [String: Any]) {
        guard let longName = json["long_name"] as? String, let shortName = json["short_name"] as? String, let types = json["types"] as? [String] else {
            return nil
        }
        self.longName = longName
        self.shortName = shortName
        self.types = types
    }
}
