//
//  MetadataDomain.swift
//  Geolocator
//
//  Created by Emory Dunn on 15 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import ImageIO

enum MetadataDomain {
    case iptc(IPTCDictionaryKey)
    case exif(EXIFDictionaryKey)
    case gps(GPSDictionaryKey)
    
    var keyName: String {
        switch self {
        case .iptc:
            return kCGImagePropertyIPTCDictionary as String
        case .exif:
            return kCGImagePropertyExifDictionary as String
        case .gps:
            return kCGImagePropertyGPSDictionary as String
        }
    }
}

enum IPTCDictionaryKey {
    case countryPrimaryLocationName
    case provinceState
    case city
    case subLocation
    
    var keyName: String {
        switch self {
        case .countryPrimaryLocationName:
            return kCGImagePropertyIPTCCountryPrimaryLocationName as String
        case .provinceState:
            return kCGImagePropertyIPTCProvinceState as String
        case .city:
            return kCGImagePropertyIPTCCity as String
        case .subLocation:
            return kCGImagePropertyIPTCSubLocation as String
        }
    }
}

enum EXIFDictionaryKey {
    case date
    
    var keyName: String {
        switch self {
        case .date:
            return kCGImagePropertyExifDateTimeOriginal as String
            
        }
    }
}

enum GPSDictionaryKey {
    case latitudeRef
    case longitudeRef
    case latitude
    case longitude
    case status
    
    var keyName: String {
        switch self {
        case .latitudeRef:
            return kCGImagePropertyGPSLatitudeRef as String
        case .longitudeRef:
            return kCGImagePropertyGPSLongitudeRef as String
        case .latitude:
            return kCGImagePropertyGPSLatitude as String
        case .longitude:
            return kCGImagePropertyGPSLongitude as String
        case .status:
            return kCGImagePropertyGPSStatus as String
            
        }
    }
}
