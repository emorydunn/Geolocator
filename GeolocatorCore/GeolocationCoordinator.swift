//
//  GeolocationCoordinator.swift
//  GeolocatorCore
//
//  Created by Emory Dunn on 8/9/19.
//  Copyright © 2019 Emory Dunn. All rights reserved.
//

import Foundation
import SwiftEXIF

public class GeolocationCoordinator {
    
    public var geocoder: ReverseGeocoder
    public var reader: MetadataReader
    
    public init(geocoder: ReverseGeocoder, reader: MetadataReader = MetadataReader()) {
        self.geocoder = geocoder
        self.reader = reader
    }
    
    public func openURLs(_ urls: [URL]) throws {
        // Load the contents of the given URLs
        let fullContents = try ImageLoader.contents(of: urls)
        
        try reader.read(from: fullContents)
    }
    
    public func writeImages() throws {
        try reader.write()
    }
    
    public func reverseGeocode() {
        reader.images.forEach {
            geocoder.reverseGeocodeLocation($0) { message in
                print(message)
            }
        }
        
    }
    
}
