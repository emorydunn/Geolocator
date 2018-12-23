//
//  ViewController.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa

struct InterfaceIdentifiers {
    static let geocodeMenuItem = NSUserInterfaceItemIdentifier("geocodeMenuItem")
    static let loadMetadataMenuItem = NSUserInterfaceItemIdentifier("loadMetadataMenuItem")
    static let geocoderApple = NSUserInterfaceItemIdentifier("geocoderApple")
    static let geocoderGoogle = NSUserInterfaceItemIdentifier("geocoderGoogle")
}

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
//                self.dataArray.append(contentsOf: images)
                self.dataArray.append(contentsOf: images.filter { image in
                    !self.dataArray.contains(image)
                })
            }
            
            if let urls = info["URLs"] as? [URL] {
                NSLog("Opening images from URLs")
                
                if let images = self.open(urls: urls) {
                    self.dataArray.append(contentsOf: images.filter { image in
                        !self.dataArray.contains(image)
                    })
//                    self.dataArray.append(contentsOf: images)
                    self.loadMetatdata(nil)
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
    
    @IBAction func loadMetatdata(_ sender: Any?) {
        let manager = MetadataManager()
        manager.loadMetatdata(from: dataArray, manuallyStart: true)
        
        var showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
        
        // If the sender is nil this was called directly, so show activity
        if sender == nil {
            showActivityView = true
        }
        
        
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
            self.reloadData(sender)
            if self.activityView != nil {
                self.dismiss(self.activityView!)
                self.activityView = nil
            }
            
            NotificationCenter.default.removeObserver(token!)
        }
        
        if dataArray.count > 50 || showActivityView {
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
    
    @IBAction func writeMetatdata(_ sender: Any) {
        let manager = MetadataManager()
        manager.writeMetadata(for: dataArray, manuallyStart: true)
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
    
    @IBAction func reloadData(_ sender: Any?) {
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
//                    self.dataArray = images
                    self.dataArray.append(contentsOf: images.filter { image in
                        !self.dataArray.contains(image)
                    })
                    self.loadMetatdata(nil)
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
    
    @IBAction func setGeocoder(_ sender: NSMenuItem) {
        
        UserDefaults.standard.set(sender.tag, forKey: "geocoderSelection")

    }


}


extension ViewController: NSUserInterfaceValidations {
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
        case #selector(reverseGeocode(_:)):
            return !dataArray.isEmpty
        case #selector(loadMetatdata(_:)):
            return !dataArray.isEmpty
        case #selector(setGeocoder(_:)):
            let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
            if let item = item as? NSMenuItem {
                item.state = NSControl.StateValue(item.tag == selectionIndex)
            }
            fallthrough
        default:
            return true
        }
        
    }
}

extension NSControl.StateValue {
    
    init(_ bool: Bool) {
        switch bool {
        case true:
            self = .on
        case false:
            self = .off
        }
    
    }
}
