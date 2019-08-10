//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 15 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import Cocoa
import SwiftEXIF

//public class LocatableImage: NSObject {
//
//}

//public class LocatableImage: NSObject, ImageMetadata {
//    public var url: URL
//    let exiftool: ExiftoolProtocol
//    
//    public var imageProperties = [String: Any]()
//    
//    public init?(url: URL) {
//        self.url = url
//        
//        let ext = url.pathExtension as CFString
//        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext, nil)
//        
//        // Only open image files
//        guard UTTypeConformsTo((uti?.takeRetainedValue())!, kUTTypeImage) else {
//            NSLog("\(url.lastPathComponent) does not conform to image")
//            return nil
//        }
//        
//        // Ignore exiftool backups
//        guard !url.lastPathComponent.hasSuffix("_original") else {
//            NSLog("\(url.lastPathComponent) is an exiftool original")
//            return nil
//        }
//        
//        guard let exiftool = Exiftool(trace: nil) else {
//            NSLog("Could not init exiftool")
//            return nil
//        }
//        
//        self.exiftool = exiftool
//    }
//    
//    public func loadMetadata() {
//        do {
//            let result = try exiftool.execute(arguments: [
//                url.path,
//                "-n", "-q", "-json", "-g"
//                ])
//
//            guard let metadata = try JSONSerialization.jsonObject(with: result.response, options: [.mutableContainers]) as? [[String : Any]] else {
//                return
//            }
//            
//            imageProperties = metadata.first!
//
//        } catch {
//            NSLog(error.localizedDescription)
//        }
//        
//        
//        
//    }
//    public func writeMetadata() {
//        
//        guard status?.bool == true else {
//            NSLog("GPS status is false, skipping write")
//            return
//        }
//
//        var arguments = [
//            url.path,
//            "-m",
//            "-overwrite_original_in_place"
//        ]
//        
//        // IPTC Location
//        if let value = country {
//            arguments.append("-IPTC:Country-PrimaryLocationName=\(value)")
//        }
//        if let value = state {
//            arguments.append("-IPTC:Province-State=\(value)")
//        }
//        if let value = city {
//            arguments.append("-IPTC:City=\(value)")
//        }
//        if let value = neighborhood {
//            arguments.append("-IPTC:Sub-location=\(value)")
//        }
//        
//        // Keywords
//        if let value = route {
//            arguments.append("-keywords=\(value)")
//        }
//        
//        do {
//            _ = try exiftool.execute(arguments: arguments)
//            NSLog("Wrote metadata for \(url.lastPathComponent)")
//        } catch {
//            NSLog(error.localizedDescription)
//        }
//    }
//    
//    // MARK: Display Values
//    @objc public var displayName: String {
//        return url.lastPathComponent
//    }
//    @objc public var displayStatus: String? {
//        return status?.description
//    }
//    @objc public var displayCoordinates: String? {
//        if latitude != 0 && longitude != 0 {
//            return "\(latitude), \(longitude)"
//        }
//        return nil
//    }
//    
//    // MARK: - IPTC
//    @objc public var country: String? {
//        get {
//            return string(for: .iptc(.countryPrimaryLocationName))
//        }
//        set {
//            set(newValue ?? "", for: .iptc(.countryPrimaryLocationName))
//        }
//    }
//
//    @objc public var state: String? {
//        get {
//            return string(for: .iptc(.provinceState))
//        }
//        set {
//            set(newValue ?? "", for: .iptc(.provinceState))
//        }
//    }
//    @objc public var city: String? {
//        get {
//            return string(for: .iptc(.city))
//        }
//        set {
//            set(newValue ?? "", for: .iptc(.city))
//        }
//
//    }
//    @objc public var route: String? {
//        return nil
//    }
//
//    @objc public var neighborhood: String? {
//        get {
//            return string(for: .iptc(.subLocation))
//        }
//        set {
//            set(newValue ?? "", for: .iptc(.subLocation))
//        }
//    }
//
//    // MARK: EXIF
//    @objc public var dateTimeOriginal: Date? {
//        return date(for: .exif(.date))
//    }
//
//
//    // MARK: GPS
//    public var latitude: Double {
//        return double(for: .composite(.latitude))
//    }
//    public var longitude: Double {
//        return double(for: .composite(.longitude))
//    }
//
//    public var status: GPSStatus? {
//        return gpsStatus(for: .exif(.status))
//    }
//
//    override public func isEqual(_ object: Any?) -> Bool {
//        return self.url == (object as? LocatableImage)?.url
//    }
//    
//    
//}
//
//extension LocatableImage: NSPasteboardWriting {
//    public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
//        return [NSPasteboard.PasteboardType.string]
//    }
//
//
//    public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
//        switch type {
//        case .string:
//            let encoder = JSONEncoder()
//            encoder.outputFormatting = .prettyPrinted
//            
//            guard JSONSerialization.isValidJSONObject(self.imageProperties) else {
//                NSLog("Properties of \(self.displayName) are not JSON encodable")
//                return nil
//            }
//
//            do {
//                let data = try JSONSerialization.data(withJSONObject: self.imageProperties, options: JSONSerialization.WritingOptions.prettyPrinted)
//
//                return String(data: data, encoding: .utf8)
//            } catch {
//                NSLog(error.localizedDescription)
//                return nil
//            }
//
//        default:
//            return nil
//        }
//    }
//
//
//}
