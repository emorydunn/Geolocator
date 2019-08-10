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
        let fileName = "\(UUID().uuidString).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Geolocator").appendingPathComponent(fileName)
        
        try reader.writeJSON(to: url)
        try reader.write(from: url)
    }
    
    public func reverseGeocode(progress: @escaping (_ current: Int, _ total: Int, _ message: String) -> Void) {
        let total = reader.images.count
        var current: Int = 0
        reader.images.enumerated().forEach { index, image in
            geocoder.reverseGeocodeLocation(image) { message in
                current += 1
                progress(current, total, message)
            }
        }
        
//        completion()
        
    }
    
}
