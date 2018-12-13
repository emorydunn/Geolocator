//
//  FolderLoader.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

struct ImageLoader {
    
    static let notificationName = Notification.Name("ImageLoader")
    
    fileprivate init() { }
    
    static func postNotification(_ images: [LocatableImage]) {
        NotificationCenter.default.post(name: ImageLoader.notificationName, object: nil, userInfo: ["Images" : images])
    }
    
    static func postNotification(_ images: [URL]) {
        NotificationCenter.default.post(name: ImageLoader.notificationName, object: nil, userInfo: ["URLs" : images])
    }
    
    static func loadImages(from urls: [URL]) -> [LocatableImage] {
        return urls.compactMap { LocatableImage(url: $0) }
    }
    
    static func contents(of urls: [URL]) throws -> [URL] {
        NSLog("Getting contents for \(urls.count) directories")
        return try urls.reduce([]) { (previous, url) in
            return try previous + contents(of: url)
        }
    }
    
    static func contents(of url: URL) throws -> [URL] {
        
        if let dcim = dcimContents(at: url) {
            NSLog("Opening \(url.lastPathComponent) as DCIM directory")
            return try contents(of: dcim)
        }
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) else {
            return []
        }

        NSLog("Opening \(contents.count) files from directory")
        return contents
//        return fileNames.map { URL(fileURLWithPath: $0, relativeTo: url) }

    }
    
    /// Attempt to get the contents of the DCIM of the URL.
    ///
    /// If the given URL contains a DCIM directory it is treated as a memory card
    /// and any valid DCIM folders will be returned.
    ///
    /// - Parameter url: URL to return the DCIM contents of
    /// - Returns: The valid DCIM contents, or `nil` if the folder does not contains a DCIM directory.
    static func dcimContents(at url: URL) -> [URL]? {
        
        // Path of potential DCIM directory
        let dcimURL = url.appendingPathComponent("DCIM")
        
        // Get the contents of the DCIM dir
        guard let dcimContents = try? FileManager.default.contentsOfDirectory(at: dcimURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) else {
            return nil
        }
        
        NSLog("Loading images from \(dcimURL.path)")
        
        // Filter for valid DCIM image directories
        return dcimContents.filter { url in
            url.lastPathComponent.range(of: "^\\d{3}\\w{5}$", options: .regularExpression) != nil
        }
        
    }
    
}
