//
//  GeolocatorPlugin.swift
//  Geolocator Plugin
//
//  Created by Emory Dunn on 23 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa
import CaptureOnePlugins

class GeolocatorPlugin: COPluginBase {
    
    
    
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
            guard let urls = task.files?.map({ URL(fileURLWithPath: $0) }) else { return COPluginActionOpenWithResult(status: false) }
            
            let success = NSWorkspace.shared.open(
                urls,
                withAppBundleIdentifier: "coffee.emory.Geolocator",
                options: NSWorkspace.LaunchOptions.default,
                additionalEventParamDescriptor: nil,
                launchIdentifiers: nil
            )
            
            return COPluginActionOpenWithResult(status: success)
        }
        
        return COPluginActionOpenWithResult(status: false)
        
        
    }
    
    func tasks(for action: COPluginAction, forFiles files: [String]) throws -> [COFileHandlingPluginTask] {
        return [COFileHandlingPluginTask(action: action, files: files)]
    }
    
    
    
    
}
