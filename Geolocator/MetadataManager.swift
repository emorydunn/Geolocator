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

// MARK: - Geocoder Operation
class ReverseGeocodeOperation: CaptureCoreOperation {
    
    let geocoder: ReverseGeocoder
    let location: LocatableImage
    
    
    let index: Int
    let manager: MetadataManager
    
    
    init(geocoder: ReverseGeocoder, location: LocatableImage, index: Int, manager: MetadataManager) {
        self.geocoder = geocoder
        self.location = location
        
        self.index = index
        self.manager = manager
    }
    
    override func main() {
        guard isCancelled == false else {
            executing(false)
            finish(true)
            return
        }
        
        executing(true)
        manager.progress.localizedDescription = "Reverse geocoding \(location.displayName)"
        
        geocoder.reverseGeocodeLocation(location) { message in
            self.executing(false)
            NSLog(message)
            
            DispatchQueue.main.async {
                self.manager.progress.localizedAdditionalDescription = message
                self.manager.progress.completedUnitCount = Int64(self.index + 1)
                
                if self.manager.progress.fractionCompleted == 1 {
                    NSLog("Progress is complete, posting notification")
                    NotificationCenter.default.post(name: MetadataManager.notificationName, object: nil)
                }
            }

            self.finish(true)

        }
    }
    
}



class MetadataManager: NSObject {
    static let notificationName = Notification.Name("MetadataManager")
    
    static let shared = MetadataManager()
 
    let queue = OperationQueue()
    
    @objc dynamic var progress: Progress!

    fileprivate override init() {
        super.init()
        
        self.progress = self.progress(for: 0)
        self.queue.qualityOfService = .userInitiated
        self.queue.underlyingQueue = DispatchQueue.main
        
        
       
        queue.maxConcurrentOperationCount = 1

    }
    
    func progress(for count: Int) -> Progress {
        // Create new progress
        let newProgress = Progress.discreteProgress(totalUnitCount: Int64(count))

        newProgress.isCancellable = true
        newProgress.isPausable = true
        newProgress.completedUnitCount = 0
        
        newProgress.pausingHandler = {
            NSLog("Pausing queue from progress handler with \(self.queue.operationCount) operations")
            self.queue.isSuspended = true
        }
        
        newProgress.resumingHandler = {
            NSLog("Resuming queue from progress handler with \(self.queue.operationCount) operations")
            self.queue.isSuspended = false
        }
        
        newProgress.cancellationHandler = {
            NSLog("Cancelling queue from progress handler with \(self.queue.operationCount) operations")
            self.queue.cancelAllOperations()
        }
        
        return newProgress
    }
    
    func resetProgress() {
        self.progress.totalUnitCount = 0
        self.progress.completedUnitCount = 0
    }

    
    func loadMetatdata(from images: [LocatableImage], manuallyStart: Bool = false) {

        self.progress.totalUnitCount += Int64(images.count)
        
        progress.pause()
        
        let operations = images.enumerated().map { index, image in
            
            return BlockOperation {
                self.progress.completedUnitCount += 1
                self.progress.localizedDescription = "Loading metatdata for \(image.displayName)"
                self.progress.localizedAdditionalDescription = ""
                image.loadMetadata()
                
                NSLog("Progress: \(self.progress.fractionCompleted). \(self.progress.completedUnitCount) / \(self.progress.totalUnitCount)")

                if self.progress.fractionCompleted == 1 {
                    NSLog("Progress is complete, posting notification")
                    NotificationCenter.default.post(name: MetadataManager.notificationName, object: self)
                }
            }
        }

        queue.addOperations(operations, waitUntilFinished: false)

    }
    
    func reverseGeocode(_ images: [LocatableImage], with geocoder: ReverseGeocoder, manuallyStart: Bool = false) {

        self.progress.totalUnitCount += Int64(images.count)
        
        progress.pause()

        let operations = images.enumerated().map { index, image in
            
            return ReverseGeocodeOperation(geocoder: geocoder, location: image, index: index, manager: self)

        }
        
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    func writeMetadata(for images: [LocatableImage], manuallyStart: Bool = false) {
        
        self.progress.totalUnitCount += Int64(images.count)
        
        progress.pause()
        
        let operations = images.enumerated().map { index, image in
            
            return BlockOperation {
                self.progress.completedUnitCount += 1
                self.progress.localizedDescription = "Writing metatdata for \(image.displayName)"
                self.progress.localizedAdditionalDescription = ""
                image.writeMetadata()
                
                //                NSLog("Progress: \(self.progress.fractionCompleted). \(self.progress.completedUnitCount) / \(self.progress.totalUnitCount)")
                
                if self.progress.fractionCompleted == 1 {
                    NotificationCenter.default.post(name: MetadataManager.notificationName, object: self)
                }
            }
        }
        
        queue.addOperations(operations, waitUntilFinished: false)
        
    }

}

