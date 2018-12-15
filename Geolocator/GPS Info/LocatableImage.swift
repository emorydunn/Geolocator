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
    
    // MARK: Display Values
    @objc dynamic var displayName: String? {
        if let url = url {
            return url.lastPathComponent
        }
        return nil
    }
    
    @objc var displayStatus: String? {
        return status?.description
    }
    
    @objc var displayCoordinates: String? {
        if latitude != 0 && longitude != 0 {
            return "\(latitude), \(longitude)"
        }
        return nil
    }
    
    
    // MARK: - Getters
    func value(for domainKey: MetadataDomain) -> Any? {
        guard var metadata = imageProperties[domainKey.keyName] as? [String: Any] else { return nil }
        
        switch domainKey {
        case .exif(let dictKey):
            return metadata[dictKey.keyName]
        case .iptc(let dictKey):
            return metadata[dictKey.keyName]
        case .gps(let dictKey):
            return metadata[dictKey.keyName]
        }
        
    }
    
    func date(for domainKey: MetadataDomain) -> Date? {
        guard let value = self.value(for: domainKey) as? String else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        
        return formatter.date(from: value)
    }
    
    func string(for domainKey: MetadataDomain) -> String? {
        return self.value(for: domainKey) as? String
    }
    
    func integer(for domainKey: MetadataDomain) -> Int {
        guard let value = self.value(for: domainKey) as? Int else { return 0 }
        
        return value
    }
    
    func double(for domainKey: MetadataDomain) -> Double {
        guard let value = self.value(for: domainKey) as? Double else { return 0 }
        
        return value
    }
    
    func direction(for domainKey: MetadataDomain) -> GPSDirection? {
        guard let value = self.value(for: domainKey) as? String else { return nil }
        
        return GPSDirection(rawValue: value)
    }
    
    func gpsStatus(for domainKey: MetadataDomain) -> GPSStatus? {
        guard let value = self.value(for: domainKey) as? String else { return nil }
        
        return GPSStatus(rawValue: value)
    }
    
    // MARK: Setters
    func set(_ value: Any, for domainKey: MetadataDomain) {
        var metadata = [String: Any]()
        
        if let existingMetadata = imageProperties[domainKey.keyName] as? [String: Any] {
            metadata = existingMetadata
        }
        
        switch domainKey {
        case .exif(let dictKey):
            metadata[dictKey.keyName] = value
        case .iptc(let dictKey):
            metadata[dictKey.keyName] = value
        case .gps(let dictKey):
            metadata[dictKey.keyName] = value
        }
        
        imageProperties[domainKey.keyName] = metadata as CFDictionary
    }
    
    // MARK: - IPTC
    @objc var country: String? {
        get {
            return string(for: .iptc(.countryPrimaryLocationName))
        }
        set {
            set(newValue ?? "", for: .iptc(.countryPrimaryLocationName))
        }
    }
    
    @objc var state: String? {
        get {
            return string(for: .iptc(.provinceState))
        }
        set {
            set(newValue ?? "", for: .iptc(.provinceState))
        }
    }
    @objc var city: String? {
        get {
            return string(for: .iptc(.city))
        }
        set {
            set(newValue ?? "", for: .iptc(.city))
        }
        
    }
    @objc var route: String? {
        return nil
    }

    @objc var neighborhood: String? {
        get {
            return string(for: .iptc(.subLocation))
        }
        set {
            set(newValue ?? "", for: .iptc(.subLocation))
        }
    }
    
    // MARK: EXIF
    @objc var dateTimeOriginal: Date? {
        return date(for: .exif(.date))
    }
    
    
    // MARK: GPS
    var latitude: Double {
        let number = double(for: .gps(.latitude))
        return latitudeRef.sign(number)
    }
    var longitude: Double {
        let number = double(for: .gps(.longitude))
        return longitudeRef.sign(number)
    }
    
    var latitudeRef: GPSDirection {
        guard let direction = direction(for: .gps(.latitudeRef)) else {
            return .north
        }
        return direction
    }
    var longitudeRef: GPSDirection {
        guard let direction = direction(for: .gps(.longitudeRef)) else {
            return .east
        }
        return direction
    }
    
    var status: GPSStatus? {
        return gpsStatus(for: .gps(.status))
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
