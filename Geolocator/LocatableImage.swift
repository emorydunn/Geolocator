//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 8/9/19.
//  Copyright © 2019 Emory Dunn. All rights reserved.
//

import Foundation
import SwiftEXIF
import GeolocatorCore

class LocatableImage: NSObject {
    
    let image: ExifImage
    
    init(image: ExifImage) {
        self.image = image
    }
    
    public var url: URL? {
        return image[TagGroup.SourceFile]
    }
    
    // MARK: Display Values
    @objc public var displayName: String {
        return image[TagGroup.File.FileName]!
    }
    
    @objc public var displayStatus: String? {
        return status?.description
    }
    
    @objc public var displayCoordinates: String? {
        if latitude != 0 && longitude != 0 {
            return "\(latitude), \(longitude)"
        }
        return nil
    }
    
    // MARK: - IPTC
    @objc public var country: String? {
        get {
            return image[TagGroup.IPTC.CountryPrimaryLocationName]
        }
        set {
            image[TagGroup.IPTC.CountryPrimaryLocationName] = newValue
//            set(newValue ?? "", for: .iptc(.countryPrimaryLocationName))
        }
    }

    @objc public var state: String? {
        get {
            return image[TagGroup.IPTC.ProvinceState]
//            return string(for: .iptc(.provinceState))
        }
        set {
            image[TagGroup.IPTC.ProvinceState] = newValue
//            set(newValue ?? "", for: .iptc(.provinceState))
        }
    }
    @objc public var city: String? {
        get {
            return image[TagGroup.IPTC.City]
//            return string(for: .iptc(.city))
        }
        set {
            image[TagGroup.IPTC.City] = newValue
//            set(newValue ?? "", for: .iptc(.city))
        }

    }
    @objc public var route: String? {
        return nil
    }

    @objc public var neighborhood: String? {
        get {
            return image[TagGroup.IPTC.Sublocation]
        }
        set {
            image[TagGroup.IPTC.Sublocation] = newValue
        }
    }

    // MARK: EXIF
    @objc public var dateTimeOriginal: Date? {
        return image[TagGroup.EXIF.DateTimeOriginal]
    }


    // MARK: GPS
    public var latitude: Double {
        return image[TagGroup.Composite.GPSLatitude] ?? 0
    }
    
    public var longitude: Double {
        return image[TagGroup.Composite.GPSLongitude] ?? 0
    }

    public var status: GPSStatus? {
        let stat = GPSStatus(image: image)
        return stat
    }

    override public func isEqual(_ object: Any?) -> Bool {
        return self.url == (object as? LocatableImage)?.url
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

            guard JSONSerialization.isValidJSONObject(self.image.metadata) else {
                NSLog("Properties of \(self.displayName) are not JSON encodable")
                return nil
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: self.image.metadata, options: JSONSerialization.WritingOptions.prettyPrinted)

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
