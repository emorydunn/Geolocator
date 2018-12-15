//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import Cocoa

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

    @objc var displayStatus: String? {
        return status?.description
    }

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
        
    }
    
    
    // MARK: - IPTC
    var iptc: [String: Any] {
        if let iptc = imageProperties["{IPTC}"] as? [String: Any] {
            return iptc
        }
        
        return [:]
    }
    
    @objc var country: String? {
        get {
            return iptc["Country/PrimaryLocationName"] as? String
        }
        set {
//            (imageProperties["{IPTC}"] as? [String: Any])["Country/PrimaryLocationName"] = newValue
        }
        
    }
    @objc var state: String? {
        get {
            return iptc["Province/State"] as? String
        }
        set {
            iptc["Province/State"] = newValue
        }
        
    }
    @objc var city: String? {
        get {
            return iptc["City"] as? String
        }
        set {
            iptc["City"] = newValue
        }
    }
    @objc var route: String? {
        get {
            return iptc["Route"] as? String
        }
        set {
            iptc["Route"] = newValue
        }
    }
    @objc var neighborhood: String? {
        get {
            return iptc["SubLocation"] as? String
        }
        set {
            iptc["SubLocation"] = newValue
        }
    }
    
    // MARK: - EXIF
    var exif: [String: Any] {
        if let exif = imageProperties["{Exif}"] as? [String: Any] {
            return exif
        }
        
        return [:]
    }
    
    @objc var dateTimeOriginal: Date? {
        guard let dateString = exif["DateTimeOriginal"] as? String else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY:MM:DD HH:mm:ss"
        
        return formatter.date(from: dateString)

    }
    
    
    // MARK: - GPS
    var gps: [String: Any] {
        if let gps = imageProperties["{GPS}"] as? [String: Any] {
            return gps
        }
        
        return [:]
    }
    
    var latitude: Double {
        guard let number = gps["Latitude", default: 0.0] as? Double else {
            return 0
        }
        
        return latitudeRef.sign(number)
    }
    var longitude: Double {
        guard let number = gps["Longitude", default: 0.0] as? Double else {
            return 0
        }
        
        return longitudeRef.sign(number)
    }
    
    var latitudeRef: GPSDirection {
        guard let direction = gps["LatitudeRef", default: "N"] as? String else {
            return .north
        }
        return GPSDirection(rawValue: direction) ?? .north
    }
    var longitudeRef: GPSDirection {
        guard let direction = gps["LongitudeRef", default: "E"] as? String else {
            return .east
        }
        return GPSDirection(rawValue: direction) ?? .east
    }
    
    var status: GPSStatus? {
        guard let statusString = gps["Status"] as? String else {
            return nil
        }
        return GPSStatus(rawValue: statusString)
    }
    
    @objc var displayCoordinates: String? {
        if latitude != 0 && longitude != 0 {
            return "\(latitude), \(longitude)"
        }
        return nil
    }
    
    
    
    

}

extension LocatableImage: NSPasteboardWriting {
    public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [NSPasteboard.PasteboardType.string]
    }
    
    
    public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .string:
            guard JSONSerialization.isValidJSONObject(self.imageProperties) else {
                NSLog("Properties of \(self.displayName ?? "no mame image") are not JSON encodable")
                return nil
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: self.imageProperties, options: JSONSerialization.WritingOptions.prettyPrinted)
                
                return String(data: data, encoding: .utf8)
            } catch {
                NSLog(error.localizedDescription)
                return nil
            }

        default:
            return nil
        }
    }
    
    
}
