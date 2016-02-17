//
//  UserViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class UserDetailsViewController: NSViewController {

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var userProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var created: NSTextField!
    @IBOutlet weak var karma: NSTextField!
    @IBOutlet var about: NSTextView!

    // MARK: Properties
    private let API = APIClient()

    // MARK: Methods
    func getUserInfo(id: String) {
        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.contentView.animator().hidden = true
            self.userProgressIndicator.animator().hidden = false
            self.userProgressIndicator.startAnimation(self)
            NSAnimationContext.endGrouping()
        }

        API.fetchUser(id) { user in
            dispatch_async(dispatch_get_main_queue()) {
                self.karma.intValue = user.karma
                self.created.objectValue = user.created
                
                if let aboutText = user.about {
                    self.about.textStorage?.appendAttributedString(CommentParser.parseFromHTMLString(aboutText))
                } else {
                    self.about.alignment = .Center
                    self.about.textStorage?.appendAttributedString(NSAttributedString(string: "No description provided."))
                    self.about.textStorage?.addAttribute(NSForegroundColorAttributeName, value: NSColor.gridColor(), range: NSMakeRange(0, self.about.textStorage!.length))
                }

                NSAnimationContext.beginGrouping()
                self.contentView.animator().hidden = false
                self.userProgressIndicator.animator().hidden = true
                self.userProgressIndicator.stopAnimation(self)
                NSAnimationContext.endGrouping()
            }
        }
    }
}
