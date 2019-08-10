//
//  IPTCLocatable.swift
//  Geolocator
//
//  Created by Emory Dunn on 12 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation
import CoreLocation

public protocol IPTCLocatable: CustomStringConvertible {
    
    var country: String? { get }
    var state: String? { get }
    var city: String?  { get }
    var route: String? { get }
    var neighborhood: String? { get }
    
}

extension IPTCLocatable {
    public var description: String {
        return "\(country ?? "none"), \(state ?? "none"), \(city ?? "none")"
    }
}

struct IPTCLocation: IPTCLocatable {
    var country: String?
    var state: String?
    var city: String?
    var route: String?
    var neighborhood: String?
}
