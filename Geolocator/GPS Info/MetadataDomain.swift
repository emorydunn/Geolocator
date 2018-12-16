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
    case composite(CompositeDictionaryKey)
    
    var keyName: String {
        switch self {
        case .iptc:
            return "IPTC"
        case .exif:
            return "EXIF"
        case .composite:
            return "Composite"
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
            return "Country-PrimaryLocationName"
        case .provinceState:
            return "Province-State"
        case .city:
            return "City"
        case .subLocation:
            return "Sub-Location"
        }
    }
}

enum EXIFDictionaryKey {
    case date
    
    case latitudeRef
    case longitudeRef
    case latitude
    case longitude
    case status
    
    var keyName: String {
        switch self {
        case .date:
            return "DateTimeOriginal"
            
        case .latitudeRef:
            return "GPSLatitudeRef"
        case .longitudeRef:
            return "GPSLongitudeRef"
        case .latitude:
            return "GPSLatitude"
        case .longitude:
            return "GPSLongitude"
        case .status:
            return "GPSStatus"
            
        }
    }
}

enum CompositeDictionaryKey {
    case latitude
    case longitude

    var keyName: String {
        switch self {
        case .latitude:
            return "GPSLatitude"
        case .longitude:
            return "GPSLongitude"
        

        }
    }
}
