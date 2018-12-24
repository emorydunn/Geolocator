//
//  GeolocatorPlugin.swift
//  Geolocator Plugin
//
//  Created by Emory Dunn on 23 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa
import CaptureOnePlugins
import GeolocatorCore

class GeolocatorPlugin: COPluginBase {
    
    let defaults = UserDefaults.init(suiteName: "coffee.emory.Geolocator")
    
    let geocoderSelection = "geocoderSelection"
    let bundle: Bundle
    
    var geocoders = [ReverseGeocoder]()
    
    override init() {
        self.bundle = Bundle(for: GeolocatorPlugin.self)
        super.init()
        
        loadGeocoders()

    }
    
    func loadGeocoders() {
        // Load Apple
        geocoders.append(AppleGeocoder())
        
        // Load Google
        guard
            let url = Bundle.main.url(forResource: "APIKeys", withExtension: "plist"),
            let keys = NSDictionary(contentsOf: url),
            let mapsKey = keys["googleMapsAPIKey"] as? String
            else {
                NSLog("Could not load Google Maps API key")
                return
                
        }
        
        geocoders.append(GoogleGeocoder(apiKey: mapsKey))
        
    }
}

extension GeolocatorPlugin: COSettings {

    func settings() throws -> [COSettingsElementsGroup] {
        
        let group = COSettingsElementsGroup(identifier: "GeocoderGroup", title: nil)
        
        let geocoderField = COSettingsListItem(identifier: geocoderSelection, title: "Geocoder")
        geocoderField.options = [
            COSettingsListOption(value: 0 as NSSecureCoding, title: "Apple"),
            COSettingsListOption(value: 1 as NSSecureCoding, title: "Google"),
        ]
        
        geocoderField.value = (defaults?.integer(forKey: geocoderSelection) ?? 0)  as NSSecureCoding
        
        group.elements.append(geocoderField)
        
        return [group]
        
    }
    
    func didUpdateValue(_ value: NSSecureCoding, forSetting identifier: String, callback: @escaping COSettingsCallback) throws {
        if identifier == geocoderSelection {
            guard let index = value as? Int else {
                callback(.refresh, nil)
                return
            }
            
            defaults?.set(index, forKey: identifier)
            callback(.refresh, nil)
        }
    }
    
    func handle(_ event: COSettingsEvent, for item: COSettingsItem, callback: @escaping COSettingsCallback) throws {
        
    }
}

extension GeolocatorPlugin: COOpenWithPlugin {
    func openWithActions(withFileInfo info: [String : NSNumber], pluginRole: COOpenWithPluginRole) throws -> [COPluginAction] {
        
        
        switch pluginRole {
        case .postProcessInDocument:
            return []
        case .postProcessOutput:
            return []
        default:
            return [
                COPluginAction(displayName: "Auto Geolocate"),
//                COPluginAction(displayName: "Geolocation")
            ]
        }
    }
    
    func startOpen(with task: COFileHandlingPluginTask, progress: @escaping COPluginTaskProgress) throws -> COPluginActionOpenWithResult {
        
        // Open files
        if task.action.displayName == "Auto Geolocate" {
            
            // Get image URLs
            guard let urls = task.files?.map({ URL(fileURLWithPath: $0) }) else { return COPluginActionOpenWithResult(status: false) }
            let images = ImageLoader.loadImages(from: urls)
            
            // Load Metadata
            MetadataManager.shared.loadMetatdata(from: images, manuallyStart: true)
            
            // Geocode
            let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
            let geocoder = geocoders[selectionIndex]
            MetadataManager.shared.reverseGeocode(images, with: geocoder, manuallyStart: true)
            
            // Save Images
            MetadataManager.shared.writeMetadata(for: images, manuallyStart: true)

            // Initial progress status
            progress(
                task,
                UInt(MetadataManager.shared.progress!.completedUnitCount),
                UInt(MetadataManager.shared.progress!.totalUnitCount),
                "Beginning reverse geolocation"
            )
            
            // Resume the queue
            MetadataManager.shared.progress.resume()
            
            // Update progress while waiting for completion
            while MetadataManager.shared.progress.fractionCompleted < 1 {
                progress(
                    task,
                    UInt(MetadataManager.shared.progress!.completedUnitCount),
                    UInt(MetadataManager.shared.progress!.totalUnitCount),
                    MetadataManager.shared.progress.localizedDescription
                )
                sleep(1)
            }

            
            return COPluginActionOpenWithResult(status: true)
        }
        
        return COPluginActionOpenWithResult(status: false)
        
        
    }
    
    func tasks(for action: COPluginAction, forFiles files: [String]) throws -> [COFileHandlingPluginTask] {
        return [COFileHandlingPluginTask(action: action, files: files)]
    }
    
    
    
    
}
