//
//  UserViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class UserDetailsPopoverViewController: NSViewController {

    @IBOutlet weak var contentView: NSStackView!
    @IBOutlet weak var userProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var created: NSTextField!
    @IBOutlet weak var karma: NSTextField!
    @IBOutlet weak var about: NSTextField!
    @IBOutlet weak var separator: NSBox!

    // MARK: Properties
    private let API = APIClient.sharedInstance

    // MARK: Methods
    func getUserInfo(id: String) {
        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.runAnimationGroup({ context in
                self.contentView.animator().hidden = true
                self.userProgressIndicator.animator().hidden = false
                self.userProgressIndicator.startAnimation(self)
                }, completionHandler: nil)
        }

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.API.fetchUser(id) { user in
                self.karma.intValue = user.karma
                self.created.objectValue = user.created

                if let aboutText = user.about {
                    self.about.attributedStringValue = aboutText
                } else {
                    self.about.hidden = true
                    self.separator.hidden = true
                }

                NSAnimationContext.runAnimationGroup({ context in
                    self.contentView.animator().hidden = false
                    self.userProgressIndicator.animator().hidden = true
                    self.userProgressIndicator.stopAnimation(self)
                    }, completionHandler: nil)
            }
        }
    }
}
