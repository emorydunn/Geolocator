//
//  ActivityViewController.swift
//  Geolocator
//
//  Created by Emory Dunn on 2018-12-12.
//  Copyright © 2018 Emory Dunn. All rights reserved.
//

import Cocoa
import GeolocatorCore

class ActivityConfiguration: NSObject {
    @objc dynamic let progress: Progress

    init(activity: @escaping (Progress) -> Void) {
        self.progress = Progress()

        super.init()
        self.progress.resumingHandler = {
            activity(self.progress)
        }
        
    }

}

class ActivityViewController: NSViewController {

    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var cancelButton: NSButton!
    
    @objc dynamic var config: ActivityConfiguration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        config.resume()
        // Do view setup here.
        config.progress.resume()

    }
    
    @IBAction override func cancelOperation(_ sender: Any?) {
//        manager.progress.cancel()
        self.dismiss(sender)
    }

}
