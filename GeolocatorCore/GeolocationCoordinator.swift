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
    
    public func openURLs(_ urls: [URL], completionHandler: @escaping (Result<String, Error>) -> Void) {
        // Load the contents of the given URLs
        do {
            let fullContents = try ImageLoader.contents(of: urls)
            
            let tags = [
                // Basic Info
                TagGroup.File.FileName.name,
                TagGroup.EXIF.DateTimeOriginal.name,
                
                // GPS Info
                TagGroup.EXIF.GPSStatus.name,
                
                TagGroup.EXIF.GPSLatitude.name,
                TagGroup.EXIF.GPSLatitudeRef.name,
                TagGroup.Composite.GPSLatitude.name,
                
                TagGroup.EXIF.GPSLongitude.name,
                TagGroup.EXIF.GPSLongitudeRef.name,
                TagGroup.Composite.GPSLongitude.name,
                
                // Existing Location info
                TagGroup.IPTC.CountryPrimaryLocationName.name,
                TagGroup.IPTC.ProvinceState.name,
                TagGroup.IPTC.City.name,
                TagGroup.IPTC.Sublocation.name
            ]
            
            reader.read(tags, from: fullContents) {
                completionHandler($0)
            }
        } catch {
            completionHandler(.failure(error))
        }
        
        
    }
    
    public func writeImages(onQueue queue: DispatchQueue = DispatchQueue.main ,completionHandler: @escaping (Result<String, Error>) -> Void) {
        
        queue.async {
            let fileName = "\(UUID().uuidString).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Geolocator").appendingPathComponent(fileName)
            
            do {
                try self.reader.writeJSON(to: url)
                self.reader.write(from: url) {
                    completionHandler($0)
                }
            } catch {
               completionHandler(.failure(error))
            }
        }
        
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
