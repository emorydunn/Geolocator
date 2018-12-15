//
//  GPSStatus.swift
//  Geolocator
//
//  Created by Emory Dunn on 14 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

public enum GPSStatus: String, Codable, CustomStringConvertible {
    case active = "A"
    case void = "V"
    
    public var description: String {
        switch self {
        case .active:
            return "Active"
        case .void:
            return "Void"
        }
    }
    
    var bool: Bool {
        switch self {
        case .active:
            return true
        case .void:
            return false
        }
    }
}
