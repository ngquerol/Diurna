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
    @IBOutlet weak var authorButton: NSButton!
    @IBOutlet weak var opButton: NSButton!
    @IBOutlet weak var timeTextField: NSTextField!
    @IBOutlet weak var textContainerView: NSView!
    @IBOutlet weak var textTextField: NSTextField!

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

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            NSColor(calibratedWhite: 0.95, alpha: 1.0).CGColor,
            NSColor(calibratedWhite: 0.975, alpha: 1.0).CGColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 5.0

        textContainerView.layer = gradientLayer

        self.addSubview(content)
    }

    // MARK: Methods
    @IBAction private func showUserDetailsPopover(sender: NSButton) {
        createUserDetailsPopover()
        userDetailsPopover.showRelativeToRect(authorButton.bounds, ofView: authorButton, preferredEdge: .MaxY)
    }

    private func createUserDetailsPopover() {
        guard let userDetailsViewController = NSStoryboard(name: "Main", bundle: nil).instantiateControllerWithIdentifier("UserDetailsViewController") as? UserDetailsViewController,
            comment = self.objectValue as? Comment else {
                return
        }

        userDetailsPopover = NSPopover()
        userDetailsPopover.contentViewController = userDetailsViewController
        userDetailsPopover.behavior = .Transient
        userDetailsPopover.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        userDetailsPopover.animates = true
        userDetailsPopover.delegate = self

        userDetailsViewController.getUserInfo(comment.by)
    }
}

// MARK: Popover Delegate
extension CommentTableCellView : NSPopoverDelegate {
    func popoverDidClose(notification: NSNotification) {
        userDetailsPopover = nil
    }
}