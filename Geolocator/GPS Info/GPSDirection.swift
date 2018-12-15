//
//  GPSDirection.swift
//  Geolocator
//
//  Created by Emory Dunn on 14 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

enum GPSDirection: String, Codable {
    case north = "N"
    case south = "S"
    case east = "E"
    case west = "W"
    
    func sign(_ number: Double) -> Double {
        switch self {
        case .north, .east:
            if number > 0 {
                return number
            }
            return -number
        case .south, .west:
            if number < 0 {
                return number
            }
            return -number
            
        }
    }
}
