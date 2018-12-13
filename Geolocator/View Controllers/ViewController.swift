//
//  ViewController.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @objc dynamic var dataArray = [LocatableImage]()
    @IBOutlet var dataArrayController: NSArrayController!
    
    var activityView: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataArrayController.sortDescriptors = [
            NSSortDescriptor(key: "displayName", ascending: true)
        ]

        NotificationCenter.default.addObserver(forName: ImageLoader.notificationName, object: nil, queue: nil) { notification in
            guard let info = notification.userInfo else {
                return
            }
            
            if let images = info["Images"] as? [LocatableImage] {
                NSLog("Setting data array to images from notification")
                self.dataArray = images
            }
            
            if let urls = info["URLs"] as? [URL] {
                NSLog("Opening images from URLs")
                
                if let images = self.open(urls: urls) {
                    self.dataArray = images
                }
                
            }
            

        }

    }
    override func viewDidAppear() {
        promptForFiles()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func open(_ sender: Any) {
        promptForFiles()
    }
    
    @IBAction func loadMetatdata(_ sender: Any) {
        let manager = MetadataManager()
        manager.loadMetatdata(from: dataArray, manuallyStart: true)
        
        NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: manager, queue: OperationQueue.main) { _ in
            self.reloadData(sender)
            if self.activityView != nil {
                self.dismiss(self.activityView!)
            }
            
            NotificationCenter.default.removeObserver(self, name: MetadataManager.notificationName, object: manager)
        }
        
        if dataArray.count > 100 {
            NSLog("Performing Segue")
            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
        } else {
            manager.progress.resume()
        }

    }
    
    @IBAction func reverseGeocode(_ sender: Any) {
        let manager = MetadataManager()
        let geocoder = AppleGeocoder()
        
        manager.reverseGeocode(dataArray, with: geocoder)
        
        NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: manager, queue: OperationQueue.main) { _ in
            self.reloadData(sender)
            if self.activityView != nil {
                self.dismiss(self.activityView!)
            }
            
            NotificationCenter.default.removeObserver(self, name: MetadataManager.notificationName, object: manager)
        }
        
        if dataArray.count > 1 {
            NSLog("Performing Segue")
            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
        } else {
            manager.progress.resume()
        }
        
    }
    
    @IBAction func reloadData(_ sender: Any) {
        print("Reloading array controller")
        dataArrayController.rearrangeObjects()
    }
    
    func open(urls: [URL]) -> [LocatableImage]? {

        do {
            let contents = try ImageLoader.contents(of: urls)
            return ImageLoader.loadImages(from: contents)
        } catch {
            presentError(error)
            return []
        }
    }
    
    func promptForFiles() {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        openPanel.beginSheetModal(for: self.view.window!) { (response) in
            
            switch response {
            case .OK:
                if let images = self.open(urls: openPanel.urls) {
                    self.dataArray = images
                }
            default:
                break
            }
            
        }

    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let dest = segue.destinationController as? ActivityViewController else {
            return
        }
        activityView = dest
        
        NSLog("Loading activityview")
    }


}

