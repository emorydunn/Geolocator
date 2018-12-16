//
//  LocatableImage.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import Cocoa

protocol ImageMetadata: AnyObject {
    var imageProperties: [String: Any] { get set }
    
    func loadMetadata()
    func writeMetadata()
    
}

extension ImageMetadata {
    
    // MARK: - Getters
    func value(for domainKey: MetadataDomain) -> Any? {
        guard var metadata = imageProperties[domainKey.keyName] as? [String: Any] else { return nil }

        switch domainKey {
        case .exif(let dictKey):
            return metadata[dictKey.keyName]
        case .iptc(let dictKey):
            return metadata[dictKey.keyName]
        case .composite(let dictKey):
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
        case .composite(let dictKey):
            metadata[dictKey.keyName] = value
        }

        imageProperties[domainKey.keyName] = metadata as CFDictionary
    }
}
