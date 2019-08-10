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

        dataArrayController.sortDescriptors = [
            NSSortDescriptor(key: "displayName", ascending: true)
        ]

        NotificationCenter.default.addObserver(forName: ImageLoader.notificationName, object: nil, queue: nil) { notification in
            guard let info = notification.userInfo else {
                return
            }

            if let urls = info["URLs"] as? [URL] {
                NSLog("Opening images from URLs")
                
                self.coordinator.openURLs(urls) {
                    switch $0 {
                    case .success(let message):
                        NSLog(message)
                        self.loadMetatdata(nil)
                    case .failure(let error):
                        self.presentError(error)
                    }
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
        let success = NSPasteboard.general.writeObjects(selectedRecords)
        NSLog("\(success ? "Wrote" : "Failed to write") \(selectedRecords.count) records to paste board")
    }
    
    @IBAction func openInMaps(_ sender: Any? = nil) {
        
        guard let selectedRecord = dataArrayController.selectedObjects as? [LocatableImage] else {
            NSLog("No selection to copy")
            return
        }
        
        do {
            try coordinator.geocoder.openMapForPlace(images: selectedRecord.map { $0.image })
        } catch {
            presentError(error)
        }
        
        
    }

    
    @IBAction func open(_ sender: Any? = nil) {
        promptForFiles()
    }
    
    @IBAction func loadMetatdata(_ sender: Any?) {
        // Create LocatableImages from the coordinator
        
        DispatchQueue.main.async {
        
            self.dataArray = self.coordinator.reader.images.map {
                LocatableImage(image: $0)
            }
            
        }

    }
    
    @IBAction func reverseGeocode(_ sender: Any? = nil) {
        
        let selectionIndex = UserDefaults.standard.integer(forKey: "geocoderSelection")
        coordinator.geocoder = geocoders[selectionIndex]
        
        
        let activity = ActivityConfiguration { progress in
            
            progress.localizedDescription = "Reverse Geocoding Images"
            progress.localizedAdditionalDescription = ""
            progress.isCancellable = false

            self.coordinator.reverseGeocode { (current, total, message) in
                
                DispatchQueue.main.async {
                    progress.completedUnitCount = Int64(current)
                    progress.totalUnitCount = Int64(total)
                    progress.localizedAdditionalDescription = "\(message)"
                    print("\(current) / \(total)", message)
                }
                
                
                if current == total {
                    DispatchQueue.main.async {
                        self.reloadData(sender)
                        self.activityView?.dismiss(nil)
                        self.view.window?.isDocumentEdited = true
                    }
                    
                }
            }
                
        }
        
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: activity)
        
    }
    
    @IBAction func writeMetatdata(_ sender: Any? = nil) {

        let activity = ActivityConfiguration { progress in
            
            progress.localizedDescription = "Writing metadata to images"
            progress.localizedAdditionalDescription = ""
            progress.totalUnitCount = 0
            progress.completedUnitCount = 0
            progress.isCancellable = false
            
           self.coordinator.writeImages(onQueue: DispatchQueue.global(qos: .utility)) { result in
                switch result {
                case .success(let message):
                    NSLog(message)
                    
                    DispatchQueue.main.async {
                        self.activityView?.dismiss(nil)
                        self.loadMetatdata(nil)
                        self.view.window?.isDocumentEdited = false
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentError(error)
                    }
                }
            }
        }
        
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("ActivityProgressSegue"), sender: activity)
        
    }
    
    @IBAction func reloadData(_ sender: Any? = nil) {
        print("Reloading array controller")
        // Save current selection
        DispatchQueue.main.async {
            let currentSelection = self.dataArrayController.selectionIndexes
            self.dataArrayController.rearrangeObjects()
            self.dataArrayController.setSelectionIndexes(currentSelection)
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
                
                self.coordinator.openURLs(openPanel.urls) {
                    switch $0 {
                    case .success(let message):
                        NSLog(message)
                        self.loadMetatdata(nil)
                    case .failure(let error):
                        self.presentError(error)
                    }
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

        dest.config = sender as? ActivityConfiguration
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
        case #selector(openInMaps(_:)):
            
            guard let selectedRecords = dataArrayController.selectedObjects as? [LocatableImage] else {
                return false
            }
            
            return selectedRecords.reduce(false) { (result, image) in
                return result || image.status.bool
            }

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
