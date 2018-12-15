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
    func reverseGeocodeLocation(_ location: LocatableImage)
}

public class AppleGeocoder: ReverseGeocoder {
    
    public init() {
        
    }
    
    public func reverseGeocodeLocation(_ location: LocatableImage) {
        let geocoder = CLGeocoder()
        let coreLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(coreLocation) { (placemarks, error) in
            guard error == nil else {
                return
            }
            guard let firstLocation = placemarks?[0] else {
                return
            }
            
            // Assign location information
//            location.country = firstLocation.country
//            location.state = firstLocation.state
//            location.city = firstLocation.city
//            location.route = firstLocation.route
//            location.neighborhood = firstLocation.neighborhood
        }
    }
}

public class GoogleGeocoder: ReverseGeocoder {

    public init() {

    }

    public func reverseGeocodeLocation(_ location: LocatableImage) {

        guard let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(location.latitude),\(location.longitude)") else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let dict = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return
            }
            
            guard let place = self.extractPlace(from: dict) else {
                return
            }
            
            

//            completionHandler(self.extractPlace(from: dict))
        }
        //        NSLog("Fetching Location from \(url.path)")
        task.resume()

    }

    func extractPlace(from json: [String: Any]) -> IPTCLocatable? {

        guard let results = json["results"] as? [[String: Any]], let firstResult = results.first else {
            return nil
        }

        guard let addressComponents = firstResult["address_components"] as? [[String: Any]] else {
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
