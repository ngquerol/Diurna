//
//  CommentTableCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentCellView: NSTableCellView {

    // MARK: Outlets
    @IBOutlet weak var replyArrowTextField: NSTextField!

    @IBOutlet var authorTextField: NSTextField!

    @IBOutlet var opBadgeView: LightColoredBadgeView!

    @IBOutlet var timeTextField: NSTextField!

    @IBOutlet var repliesButton: DisclosureButtonView!

    @IBOutlet var repliesTextField: NSTextField!

    @IBOutlet var commentTextView: MarkupTextView! {
        didSet {
            commentTextView.backgroundColor = Themes.current.backgroundColor
            commentTextView.textColor = Themes.current.normalTextColor
        }
    }

    // MARK: Properties
    override var objectValue: Any? {
        didSet {
            guard let comment = objectValue as? Comment else {
                return
            }

            timeTextField.stringValue = comment.time.timeIntervalString
            timeTextField.toolTip = comment.time.description(with: Locale.autoupdatingCurrent)
            timeTextField.textColor = Themes.current.secondaryTextColor

            guard comment.deleted != true else {
                commentTextView.attributedStringValue = .empty
                opBadgeView.isHidden = true
                authorTextField.isEnabled = false
                authorTextField.stringValue = "[deleted]"
                authorTextField.textColor = Themes.current.disabledTextColor
                timeTextField.textColor = Themes.current.disabledTextColor
                return
            }

            if let author = comment.by {
                authorTextField.stringValue = author
                authorTextField.isEnabled = true
                authorTextField.toolTip = "See \(author)'s profile"
            } else {
                authorTextField.stringValue = "unknown"
                authorTextField.isEnabled = false
                authorTextField.toolTip = ""
            }

            authorTextField.textColor = Themes.current.primaryTextColor
            commentTextView.attributedStringValue = comment.text?.parseMarkup() ?? .empty
        }
    }

    var isExpandable: Bool = false {
        didSet {
            repliesButton.isHidden = !isExpandable
            repliesTextField.isHidden = !isExpandable
        }
    }

    var isExpanded: Bool = false {
        didSet {
            repliesButton.isExpanded = isExpandable && isExpanded
            repliesTextField.animator().isHidden = !isExpandable || isExpanded
        }
    }

    private lazy var userDetailsPopover: NSPopover = {
        let userDetailsPopoverViewController = UserDetailsPopoverViewController(nibName: .userDetailsPopover, bundle: nil),
            popover = NSPopover()

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = userDetailsPopoverViewController

        return popover
    }()

    // MARK: Actions
    @IBAction private func toggleReplies(_: NSButton) {
        let toggleChildren = NSEvent.modifierFlags.contains(.option)

        isExpanded = !isExpanded

        NotificationCenter.default.post(
            name: .toggleCommentRepliesNotification,
            object: self,
            userInfo: [
                "toggleChildren": toggleChildren,
            ]
        )
    }

    @IBAction private func showUserDetailsPopover(_: NSTextField) {
        guard
            let user = (objectValue as? Comment)?.by,
            let userDetailsPopoverViewController = userDetailsPopover.contentViewController as? UserDetailsPopoverViewController
        else {
            return
        }

        userDetailsPopover.show(
            relativeTo: authorTextField.bounds,
            of: authorTextField,
            preferredEdge: .maxY
        )

        userDetailsPopoverViewController.show(user)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let toggleCommentRepliesNotification = Notification.Name("ToggleCommentRepliesNotification")
}

// MARK: - NSUserInterfaceItemIdentifier
extension NSUserInterfaceItemIdentifier {
    static let commentCell = NSUserInterfaceItemIdentifier("CommentCell")
}

// MARK: - NSPopover Delegate
extension CommentCellView: NSPopoverDelegate {}
