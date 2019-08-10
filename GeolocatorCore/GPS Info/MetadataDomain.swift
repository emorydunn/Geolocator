//
//  MetadataDomain.swift
//  Geolocator
//
//  Created by Emory Dunn on 15 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import ImageIO
import SwiftEXIF

public enum MetadataDomain {
    case iptc(IPTCDictionaryKey)
    case exif(EXIFDictionaryKey)
    case composite(CompositeDictionaryKey)
    
    public var keyName: String {
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

public enum IPTCDictionaryKey {
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
            return "Sub-location"
        }
    }
}

public enum EXIFDictionaryKey {
    case date
    
    case latitudeRef
    case longitudeRef
    case latitude
    case longitude
    case status
    
    public var keyName: String {
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

public enum CompositeDictionaryKey {
    case latitude
    case longitude

    public var keyName: String {
        switch self {
        case .latitude:
            return "GPSLatitude"
        case .longitude:
            return "GPSLongitude"
        

        }
    }
}

//extension TagGroup {
//    
//    public struct File {
//        public static let FileName = Exiftag<String>("File:FileName")
//    }
//    
//    public struct Composite {
//        fileprivate init() { }
//        
//        public static let Aperture         = Exiftag<Double>("Composite:Aperture")
//        public static let CFAPattern       = Exiftag<String>("Composite:CFAPattern")
//        public static let FocalLength35efl = Exiftag<Double>("Composite:FocalLength35efl")
//        public static let GPSAltitude      = Exiftag<Double>("Composite:GPSAltitude")
//        public static let GPSDateTime      = Exiftag<Date>("Composite:GPSDateTime")
//        public static let GPSLatitude      = Exiftag<Double>("Composite:GPSLatitude")
//        public static let GPSLongitude     = Exiftag<Double>("Composite:GPSLongitude")
//        public static let GPSPosition      = Exiftag<String>("Composite:GPSPosition")
//        public static let ImageSize        = Exiftag<String>("Composite:ImageSize")
//        public static let LensID           = Exiftag<String>("Composite:LensID")
//        public static let LightValue       = Exiftag<Double>("Composite:LightValue")
//        public static let Megapixels       = Exiftag<Double>("Composite:Megapixels")
//        public static let ShutterSpeed     = Exiftag<Double>("Composite:ShutterSpeed")
//    }
//}
