//
//  ActivityViewController.swift
//  Geolocator
//
//  Created by Emory Dunn on 2018-12-12.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa
import GeolocatorCore

class ActivityViewController: NSViewController {

    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var cancelButton: NSButton!
    
//    @objc dynamic var manager = MetadataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        manager.progress.resume()

    }
    
    @IBAction override func cancelOperation(_ sender: Any?) {
//        manager.progress.cancel()
        self.dismiss(sender)
    }

}
