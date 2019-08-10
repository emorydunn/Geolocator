//
//  ViewController.swift
//  Geolocator
//
//  Created by Emory Dunn on 11 December, 2018.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa
import GeolocatorCore
import SwiftEXIF

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
//    var reader = MetadataReader()
    
    var coordinator: GeolocationCoordinator!
    
    var activityView: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadGeocoders()
        
        let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
        coordinator = GeolocationCoordinator(geocoder: geocoders[selectionIndex])
        
        
        if let url = Bundle.main.url(forResource: "exiftool", withExtension: nil) {
            coordinator.reader.exiftool.exiftoolLocation = url.path
        }
//        guard let url = Exiftool.bundle.url(forResource: "exiftool", withExtension: nil) else {
//            NSLog("Could not find exiftool in resources of \(Exiftool.bundle.bundleURL.path)")
//            return nil
//        }


        dataArrayController.sortDescriptors = [
            NSSortDescriptor(key: "displayName", ascending: true)
        ]

//        NotificationCenter.default.addObserver(forName: ImageLoader.notificationName, object: nil, queue: nil) { notification in
//            guard let info = notification.userInfo else {
//                return
//            }
//
//            if let images = info["Images"] as? [LocatableImage] {
//                NSLog("Setting data array to images from notification")
////                self.dataArray.append(contentsOf: images)
//                self.dataArray.append(contentsOf: images.filter { image in
//                    !self.dataArray.contains(image)
//                })
//            }
//
//            if let urls = info["URLs"] as? [URL] {
//                NSLog("Opening images from URLs")
//
//                if let images = self.open(urls: urls) {
//                    self.dataArray.append(contentsOf: images.filter { image in
//                        !self.dataArray.contains(image)
//                    })
////                    self.dataArray.append(contentsOf: images)
//                    self.loadMetatdata(nil)
//                }
//
//            }
//
//
//        }

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
        if dataArray.isEmpty {
            promptForFiles()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func copy(_ sender: Any? = nil) {
        guard let selectedRecords = dataArrayController.selectedObjects as? [LocatableImage] else {
            NSLog("No selection to copy")
            return
        }
        
        NSPasteboard.general.clearContents()
//        let success = NSPasteboard.general.writeObjects(selectedRecords)
//        NSLog("\(success ? "Wrote" : "Failed to write") \(selectedRecords.count) records to paste board")
    }

    
    @IBAction func open(_ sender: Any? = nil) {
        promptForFiles()
    }
    
    @IBAction func loadMetatdata(_ sender: Any?) {
        // Create LocatableImages from the coordinator
        
        self.dataArray = coordinator.reader.images.map {
            LocatableImage(image: $0)
        }
        
//        coordinator.
//        let manager = MetadataManager.shared
//        manager.loadMetatdata(from: dataArray, manuallyStart: true)
//
//        var showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
//
//        // If the sender is nil this was called directly, so show activity
//        if dataArray.isEmpty {
//            showActivityView = false
//        } else if sender == nil {
//            showActivityView = true
//        } else if dataArray.count > 50 {
//            showActivityView = true
//        }
//
//        var token: NSObjectProtocol?
//        token = NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
//            NotificationCenter.default.removeObserver(token!)
//
//            if self.activityView != nil {
//                print("Dismissing activity view")
//                self.dismiss(self.activityView!)
//                self.activityView = nil
//            }
//
//            manager.resetProgress()
//            self.reloadData(sender)
//
//        }
//
//        if showActivityView && self.activityView == nil {
//            NSLog("Performing Segue")
//            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
//        } else {
//            manager.progress.resume()
//        }

    }
    
    @IBAction func reverseGeocode(_ sender: Any? = nil) {
        
        let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
        coordinator.geocoder = geocoders[selectionIndex]
        
        coordinator.reverseGeocode()
        
        reloadData(sender)
//        let manager = MetadataManager.shared
//
//        let showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
//
//        let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
//        let geocoder = geocoders[selectionIndex]
//
//        manager.reverseGeocode(dataArray, with: geocoder, manuallyStart: true)
//
//        var token: NSObjectProtocol?
//        token = NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
//            NSLog("MetadataManager notification received")
//
//            if self.activityView != nil {
//                self.dismiss(self.activityView!)
//                self.activityView = nil
//            }
//
//            manager.resetProgress()
//            self.reloadData(sender)
//
//            NotificationCenter.default.removeObserver(token!)
//        }
//
//        if dataArray.count > geocoder.showActivityCount || showActivityView {
//            NSLog("Performing Segue")
//            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
//        } else {
//            manager.progress.resume()
//        }
        
    }
    
    @IBAction func writeMetatdata(_ sender: Any? = nil) {
        
        do {
            try coordinator.writeImages()
        } catch {
            presentError(error)
        }
        
//        let manager = MetadataManager.shared
//        manager.writeMetadata(for: dataArray, manuallyStart: true)
//        let showActivityView = UserDefaults.standard.bool(forKey: "showActivityView")
//
//        var token: NSObjectProtocol?
//        token = NotificationCenter.default.addObserver(forName: MetadataManager.notificationName, object: nil, queue: OperationQueue.main) { _ in
//
//            if self.activityView != nil {
//                self.dismiss(self.activityView!)
//                self.activityView = nil
//            }
//            manager.resetProgress()
//            self.reloadData(sender)
//
//            NotificationCenter.default.removeObserver(token!)
//        }
//
//        if dataArray.count > 100 || showActivityView {
//            NSLog("Performing Segue")
//            performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: manager)
//        } else {
//            manager.progress.resume()
//        }
        
    }
    
    @IBAction func reloadData(_ sender: Any? = nil) {
        print("Reloading array controller")
        dataArrayController.rearrangeObjects()
    }
    
//    func open(urls: [URL]) -> [LocatableImage]? {
//
//        do {
//
////            let contents = try ImageLoader.contents(of: urls)
////            return ImageLoader.loadImages(from: contents)
//        } catch {
//            presentError(error)
//            return []
//        }
//    }
//
    func promptForFiles() {
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        openPanel.beginSheetModal(for: self.view.window!) { (response) in
            
            switch response {
            case .OK:
                do {
                    try self.coordinator.openURLs(openPanel.urls)
                } catch {
                    self.presentError(error)
                }
                
//                if let images = self.open(urls: openPanel.urls) {
////                    self.dataArray = images
//                    self.dataArray.append(contentsOf: images.filter { image in
//                        !self.dataArray.contains(image)
//                    })
                    self.loadMetatdata(nil)
//                }
                
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

        activityView = dest

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
