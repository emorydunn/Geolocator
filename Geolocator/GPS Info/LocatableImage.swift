//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 15 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import Cocoa

class LocatableImage: NSObject, ImageMetadata {
    var url: URL
    let exiftool: ExiftoolProtocol
    
    var imageProperties = [String: Any]()
    
    init?(url: URL) {
        self.url = url
        
        // Ignore exiftool backups
        guard !url.lastPathComponent.hasSuffix("_original") else {
            return nil
        }
        
        guard let exiftool = Exiftool(trace: nil) else {
            return nil
        }
        
        self.exiftool = exiftool
    }
    
    func loadMetadata() {
        do {
            let result = try exiftool.execute(arguments: [
                url.path,
                "-n", "-q", "-json", "-g"
                ])

            guard let metadata = try JSONSerialization.jsonObject(with: result.response, options: [.mutableContainers]) as? [[String : Any]] else {
                return
            }
            
            imageProperties = metadata.first!

        } catch {
            NSLog(error.localizedDescription)
        }
        
        
        
    }
    func writeMetadata() {
        
        guard status?.bool == true else {
            NSLog("GPS status is false, skipping write")
            return
        }

        var arguments = [
            url.path,
            "-m"
        ]
        
        // IPTC Location
        if let value = country {
            arguments.append("-IPTC:Country-PrimaryLocationName=\(value)")
        }
        if let value = state {
            arguments.append("-IPTC:Province-State=\(value)")
        }
        if let value = city {
            arguments.append("-IPTC:City=\(value)")
        }
        if let value = neighborhood {
            arguments.append("-IPTC:Sub-location=\(value)")
        }
        
        // Keywords
        if let value = route {
            arguments.append("-keywords=\(value)")
        }
        
        do {
            _ = try exiftool.execute(arguments: arguments)
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    // MARK: Display Values
    @objc var displayName: String {
        return url.lastPathComponent
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
        return double(for: .composite(.latitude))
    }
    var longitude: Double {
        return double(for: .composite(.longitude))
    }

    var status: GPSStatus? {
        return gpsStatus(for: .exif(.status))
    }
    
    
}

extension LocatableImage: NSPasteboardWriting {
    public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [NSPasteboard.PasteboardType.string]
    }


    public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .string:
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            guard JSONSerialization.isValidJSONObject(self.imageProperties) else {
                NSLog("Properties of \(self.displayName) are not JSON encodable")
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
