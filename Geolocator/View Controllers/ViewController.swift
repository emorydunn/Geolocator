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
    
    var geocoders = [ReverseGeocoder]()
    
    var activityView: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadGeocoders()

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
    
    override func viewDidAppear() {
        view.window?.titleVisibility = .hidden
        promptForFiles()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func copy(_ sender: Any) {
        guard let selectedRecords = dataArrayController.selectedObjects as? [LocatableImage] else {
            NSLog("No selection to copy")
            return
        }
        
        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.writeObjects(selectedRecords)
        NSLog("\(success ? "Wrote" : "Failed to write") \(selectedRecords.count) records to paste board")
    }

    
    @IBAction func open(_ sender: Any) {
        promptForFiles()
    }
    
    @IBAction func loadMetatdata(_ sender: Any) {
        let manager = MetadataManager()
        manager.loadMetatdata(from: dataArray, manuallyStart: true)
        let showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
        
        NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
            self.reloadData(sender)
            if self.activityView != nil {
                self.dismiss(self.activityView!)
                self.activityView = nil
            }
            
            NotificationCenter.default.removeObserver(self, name: MetadataManager.notificationName, object: nil)
        }
        
        if dataArray.count > 100 || showActivityView {
            NSLog("Performing Segue")
            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
        } else {
            manager.progress.resume()
        }

    }
    
    @IBAction func reverseGeocode(_ sender: Any) {
        let manager = MetadataManager()
        
        let showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
        
        let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
        let geocoder = geocoders[selectionIndex]

        manager.reverseGeocode(dataArray, with: geocoder, manuallyStart: true)
        
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
            NSLog("MetadataManager notification received")
            self.reloadData(sender)
            if self.activityView != nil {
                self.dismiss(self.activityView!)
                self.activityView = nil
            }
            
            NotificationCenter.default.removeObserver(token!)
        }
        
        if dataArray.count > geocoder.showActivityCount || showActivityView {
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
            NSLog("Could not get destination as ActivityViewController")
            return
        }
        
        guard let manager = sender as? MetadataManager else {
            NSLog("Could not get sender as MetadataManager")
            return
        }
        
        activityView = dest
        dest.manager = manager
        
        NSLog("Loading activityview")
    }


}

