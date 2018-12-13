//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

public enum GPSStatus: String, Codable {
    case active = "A"
    case void = "V"
}

enum GPSDirection: String, Codable {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    
    func sign(_ number: Double) -> Double {
        switch self {
        case .north, .east:
            if number > 0 {
                return number
            }
            return -number
        case .south, .west:
            if number < 0 {
                return number
            }
            return -number
            
        }
    }
}

public class LocatableImage: NSObject {
    
    /// File system location
    let url: URL?
    
    var imageProperties: [String: Any] = [:]
    
    @objc dynamic var displayName: String? {
        if let url = url {
            return url.lastPathComponent
        }
        return nil
    }
    
    var latitude: Double = 0
    var longitude: Double = 0
    
    var latitudeRef: GPSDirection = .north
    var longitudeRef: GPSDirection = .west
    
    var status: GPSStatus = .void
    
    @objc var displayCoordinates: String = ""
    
    @objc var displayStatus: String {
        return status.rawValue
    }
    
    @objc var country: String?
    @objc var state: String?
    @objc var city: String?
    @objc var route: String?
    @objc var neighborhood: String?
    
    
    init?(url: URL) {
        self.url = url
        
        let ext = url.pathExtension as CFString
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil)
        
        guard UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeImage) else {
            return nil
        }

    }
    
    func loadMetadata() {
        guard let url = url else {
            return
        }
        
        NSLog("Loading metadata for \(displayName ?? "no name")")
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
                return
        }
        
        self.imageProperties = properties
        
        // Set properties
        let latitudeRef = GPSDirection(rawValue: gps["LatitudeRef", default: "N"] as! String)
        let longitudeRef = GPSDirection(rawValue: gps["LongitudeRef", default: "W"] as! String)
        
        latitude = latitudeRef!.sign(gps["Latitude", default: 0.0] as! Double)
        longitude = longitudeRef!.sign(gps["Longitude", default: 0.0] as! Double)
        
        if latitude != 0 && longitude != 0 {
            displayCoordinates = "\(latitude), \(longitude)"
        }
        
    }
    
    
    
    var iptc: [String: Any] {
        if let iptc = imageProperties["{IPTC}"] as? [String: Any] {
            return iptc
        }
        
        return [:]
    }
    
    var exif: [String: Any] {
        if let exif = imageProperties["{EXIF}"] as? [String: Any] {
            return exif
        }
        
        return [:]
    }
    
    
    // GPS
    var gps: [String: Any] {
        if let gps = imageProperties["{GPS}"] as? [String: Any] {
            return gps
        }
        
        return [:]
    }
    
    
    
//    init(latitude: Double = 0, longitude: Double = 0, status: GPSStatus = .void, country: String? = nil, state: String? = nil, city: String? = nil, route: String? = nil, neighborhood: String? = nil) {
//        
//        self.url = nil
//        
//        self.latitude = latitude
//        self.longitude = longitude
//        self.status = status
//        
//        self.country = country
//        self.state = state
//        self.city = city
//        self.route = route
//        self.neighborhood = neighborhood
//    }
    
}

