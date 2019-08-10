//
//  ReverseGeocoder.swift
//  Geolocator
//
//  Created by Emory Dunn on 12 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftEXIF
import MapKit

typealias GPSPosition = (latitude: Double, longitude: Double)

enum ReverseGeocoderError: Error, LocalizedError {
    case imageHasNoCoordinates(_ image: ExifImage, description: String)
    case imageGPSStatusIsVoid(_ image: ExifImage, description: String)
    
    var errorDescription: String? {
        switch self {
        case .imageGPSStatusIsVoid(_, let description):
            return description
        case .imageHasNoCoordinates(_, let description):
            return description
        }
    }
    
    var failureReason: String? {
        switch self {
        case .imageGPSStatusIsVoid(let image, _):
            return "The GPS Status of \(image[TagGroup.File.FileName]!) is void."
        case .imageHasNoCoordinates(let image, _):
            return "\(image[TagGroup.File.FileName]!) has no GPS coordinates."
        }
    }
    
    var recoverySuggestion: String? {
        return failureReason
    }
    
}

public protocol ReverseGeocoder {
    var showActivityCount: Int { get }
        
    func reverseGeocodeLocation(_ location: ExifImage, complete: @escaping (_ message: String) -> Void)
    
}

extension ReverseGeocoder {
    
    func signedCoordinates(of image: ExifImage) -> GPSPosition {
        
        let latitude = image[TagGroup.EXIF.GPSLatitude] ?? 0
        let latRef = image[TagGroup.EXIF.GPSLatitudeRef] ?? ""
        let latDir = GPSDirection(rawValue: latRef)
        let signedLat = latDir?.sign(latitude) ?? 0
        
        
        let longitude = image[TagGroup.EXIF.GPSLongitude] ?? 0
        let longRef = image[TagGroup.EXIF.GPSLongitudeRef] ?? ""
        let longDir = GPSDirection(rawValue: longRef)
        let signedLong = longDir?.sign(longitude) ?? 0
        
        
        return GPSPosition(signedLat, signedLong)
//        return GPSDirection(rawValue: latRef)
        
    }
    
    
    /// Opens the specified image on a map.
    ///
    /// Modified from https://stackoverflow.com/a/28622266 & https://stackoverflow.com/a/32484331
    /// - Parameter image: The image to open
    public func openMapForPlace(images: [ExifImage]) throws {
        
        // Make MapItems
        let mapItems = images.compactMap { try? makeMapItem(forImage: $0) }

        MKMapItem.openMaps(with: mapItems)
    
    }
    
    func makeMapItem(forImage image: ExifImage) throws -> MKMapItem {
        guard GPSStatus(image: image)?.bool == true else {
            throw ReverseGeocoderError.imageGPSStatusIsVoid(image, description: "Could not open image on a map.")
        }

        guard
            let latitude = image[TagGroup.Composite.GPSLatitude],
            let longitude = image[TagGroup.Composite.GPSLongitude]
        else {
            throw ReverseGeocoderError.imageHasNoCoordinates(image, description: "Could not open image on a map.")
        }

        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = image[TagGroup.File.FileName]!
        
        return mapItem
    }
    
}

public class AppleGeocoder: ReverseGeocoder {
    
    public let showActivityCount: Int = 100
    
    public init() {
        
    }
    
    public func reverseGeocodeLocation(_ location: ExifImage, complete: @escaping (_ message: String) -> Void) {
        NSLog("Begin reverse geocode for \(location[TagGroup.File.FileName]!)")
        
        
        guard GPSStatus(image: location)?.bool == true else {
            complete("GPS status is false")
            return
        }
        
        let geocoder = CLGeocoder()
        
        let latitude = location[TagGroup.Composite.GPSLatitude] ?? 0
        let longitude = location[TagGroup.Composite.GPSLongitude] ?? 0
        let coreLocation = CLLocation(latitude: latitude, longitude: longitude)
        geocoder.reverseGeocodeLocation(coreLocation) { (placemarks, error) in
            guard error == nil else {
                complete(error!.localizedDescription)
                return
            }
            guard let firstLocation = placemarks?[0] else {
                complete("No location found for \(location[TagGroup.File.FileName]!)")
                return
            }
            
            // Assign location information
            location[TagGroup.IPTC.CountryPrimaryLocationName] = firstLocation.country
            location[TagGroup.IPTC.ProvinceState] = firstLocation.administrativeArea
            location[TagGroup.IPTC.City] = firstLocation.locality
//            location.route = firstLocation.route
            location[TagGroup.IPTC.Sublocation] = firstLocation.subLocality
            
            complete("Assigning location information to \(location[TagGroup.File.FileName]!)")
        }
    }
    
}

public class GoogleGeocoder: ReverseGeocoder {
    
    public let showActivityCount: Int = 50
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func reverseGeocodeLocation(_ location: ExifImage, complete: @escaping (_ message: String) -> Void) {
        NSLog("Begin reverse geocode for \(location[TagGroup.File.FileName]!)")
        
        guard GPSStatus(image: location)?.bool == true else {
            complete("GPS status is false")
            return
        }
        
        let latitude = location[TagGroup.Composite.GPSLatitude] ?? 0
        let longitude = location[TagGroup.Composite.GPSLongitude] ?? 0

        let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=\(apiKey)"
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
            location[TagGroup.IPTC.CountryPrimaryLocationName] = place.country
            location[TagGroup.IPTC.ProvinceState] = place.state
            location[TagGroup.IPTC.City] = place.city
//            location.route = place.route
            location[TagGroup.IPTC.Sublocation] = place.neighborhood
            
            complete("Assigning location information to \(location[TagGroup.File.FileName]!)")

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
