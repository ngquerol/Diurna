//
//  CommentTableCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentTableCellView : NSTableCellView {

    // MARK: Outlets
    @IBOutlet var contentView: NSTableCellView!
    @IBOutlet weak var author: NSButton!
    @IBOutlet weak var op: NSButton!
    @IBOutlet weak var time: NSTextField!
    @IBOutlet weak var text: NSTextField!

    @IBAction func showUserDetailsPopover(sender: NSButton) {
        createUserDetailsPopover()
        userDetailsPopover.showRelativeToRect(author.bounds, ofView: author, preferredEdge: .MaxY)
    }

    // MARK: Properties
    private var userDetailsPopover: NSPopover!
    private var userDetailsViewController: NSViewController!

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("CommentTableCellView", owner: self, topLevelObjects: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
        self.addSubview(content)
    }

    // MARK: Methods
    private func createUserDetailsPopover() {
        let userDetailsViewController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("UserDetailsViewController") as! UserDetailsViewController

        userDetailsPopover = NSPopover()
        userDetailsPopover.contentViewController = userDetailsViewController
        userDetailsPopover.behavior = .Transient
        userDetailsPopover.animates = true
        userDetailsPopover.delegate = self
        
        userDetailsViewController.getUserInfo(author.title)
    }
}

// MARK: Popover Delegate
extension CommentTableCellView : NSPopoverDelegate {
    func popoverDidClose(notification: NSNotification) {
        userDetailsPopover = nil
    }
}