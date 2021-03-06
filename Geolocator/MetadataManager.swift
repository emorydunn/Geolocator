//
//  MetadataManager.swift
//  Geolocator
//
//  Created by Emory Dunn on 2018-12-12.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Foundation

// From https://agostini.tech/2017/07/30/understanding-operation-and-operationqueue-in-swift/
public class CaptureCoreOperation: Operation {
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    public override var isExecuting: Bool {
        return _executing
    }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    public override var isFinished: Bool {
        return _finished
    }
    
    func executing(_ executing: Bool) {
        _executing = executing
    }
    
    func finish(_ finished: Bool) {
        _finished = finished
    }
    
}


class MetadataManager: NSObject, ProgressReporting {
    static let notificationName = Notification.Name("MetadataManager")
 
    let queue = OperationQueue.main
    
    var progress: Progress

    override init() {
        progress = Progress(totalUnitCount: 0)
        super.init()
       
        queue.maxConcurrentOperationCount = 1

    }
    
    func progress(for count: Int) -> Progress {
        self.progress = Progress.discreteProgress(totalUnitCount: Int64(count))
        
        progress.becomeCurrent(withPendingUnitCount: Int64(count))
        
        progress.isCancellable = true
        progress.completedUnitCount = 0
        
        progress.pausingHandler = {
            self.queue.isSuspended = true
        }
        
        progress.resumingHandler = {
            self.queue.isSuspended = false
        }
        
        progress.cancellationHandler = {
            self.queue.cancelAllOperations()
        }
        
        return progress
    }

    
    func loadMetatdata(from images: [LocatableImage], manuallyStart: Bool = false) {

        self.progress = progress(for: images.count)
        queue.isSuspended = manuallyStart
        
        let operations = images.enumerated().map { index, image in
            
            return BlockOperation {
                self.progress.completedUnitCount = Int64(index + 1)
                self.progress.localizedAdditionalDescription = "Loading metatdata for \(image.displayName ?? "No Name")"
                image.loadMetadata()
                
//                NSLog("Progress: \(self.progress.fractionCompleted). \(self.progress.completedUnitCount) / \(self.progress.totalUnitCount)")

                if self.progress.fractionCompleted == 1 {
                    NotificationCenter.default.post(name: MetadataManager.notificationName, object: self)
                }
            }
        }

        queue.addOperations(operations, waitUntilFinished: false)

    }
    
    func reverseGeocode(_ images: [LocatableImage], with geocoder: ReverseGeocoder, manuallyStart: Bool = false) {
        self.progress = progress(for: images.count)
        queue.isSuspended = manuallyStart
        
        let operations = images.enumerated().map { index, image in
            
            return BlockOperation {
                self.progress.completedUnitCount = Int64(index + 1)
                self.progress.localizedAdditionalDescription = "Reverse geocoding \(image.displayName ?? "No Name")"
                
                geocoder.reverseGeocodeLocation(image)

                if self.progress.fractionCompleted == 1 {
                    NotificationCenter.default.post(name: MetadataManager.notificationName, object: self)
                }
            }
        }
        
        queue.addOperations(operations, waitUntilFinished: false)
    }

}

