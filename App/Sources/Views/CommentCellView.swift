//
//  CommentTableCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class CommentCellView: NSTableCellView {
    // MARK: Outlets

    @IBOutlet var replyArrowTextField: ClickableTextField! {
        didSet {
            replyArrowTextField.toolTip = "Go to parent comment"
        }
    }

    @IBOutlet var authorTextField: NSTextField!

    @IBOutlet var opBadgeView: LightColoredBadgeView! {
        didSet {
            opBadgeView.toolTip = "Story author"
        }
    }

    @IBOutlet var timeTextField: NSTextField!

    @IBOutlet var repliesButton: DisclosureButtonView! {
        didSet {
            repliesButton.isHidden = true
        }
    }

    @IBOutlet var repliesTextField: NSTextField! {
        didSet {
            repliesTextField.isHidden = true
        }
    }

    @IBOutlet var textView: MarkupTextView!

    @IBOutlet var trailingSpacingConstraint: NSLayoutConstraint!

    // MARK: Properties

    override var objectValue: Any? {
        didSet {
            guard let comment = objectValue as? Comment else {
                return
            }

            timeTextField.stringValue = comment.time.timeIntervalString
            timeTextField.toolTip = comment.time.description(with: .autoupdatingCurrent)

            guard comment.deleted != true else {
                replyArrowTextField.textColor = .disabledControlTextColor
                opBadgeView.isHidden = true
                authorTextField.isEnabled = false
                authorTextField.stringValue = "[deleted]"
                authorTextField.textColor = .disabledControlTextColor
                authorTextField.toolTip = "This comment was deleted"
                timeTextField.textColor = .disabledControlTextColor
                textView.attributedStringValue = .empty
                return
            }

            replyArrowTextField.textColor = .secondaryLabelColor
            authorTextField.textColor = .labelColor
            timeTextField.textColor = .secondaryLabelColor

            if let author = comment.by {
                authorTextField.stringValue = author
                authorTextField.isEnabled = true
                authorTextField.toolTip = "See \(author)'s profile"
            } else {
                authorTextField.stringValue = "unknown"
                authorTextField.isEnabled = false
                authorTextField.toolTip = nil
            }

            textView.attributedStringValue = comment.text?.parseMarkup() ?? .empty
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
            repliesTextField.isHidden = !isExpandable || isExpanded
        }
    }

    private lazy var userDetailsPopover: NSPopover = {
        let userDetailsPopoverViewController = UserDetailsPopoverViewController(
            nibName: .userDetailsPopover, bundle: nil
        )
        let popover = NSPopover()

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = userDetailsPopoverViewController
        popover.contentViewController = userDetailsPopoverViewController

        return popover
    }()

    // MARK: Actions

    @IBAction private func toggleReplies(_: NSButton) {
        let toggleChildren = NSEvent.modifierFlags.contains(.option)

        isExpanded.toggle()

        NotificationCenter.default.post(
            name: .toggleCommentRepliesNotification,
            object: self,
            userInfo: [
                "toggleChildren": toggleChildren
            ]
        )
    }

    @IBAction private func goToParentComment(_: ClickableTextField) {
        guard let comment = objectValue as? Comment else {
            return
        }

        NotificationCenter.default.post(
            name: .goToParentCommentNotification,
            object: self,
            userInfo: [
                "childComment": comment
            ]
        )
    }

    @IBAction private func showUserDetailsPopover(_: NSTextField) {
        guard
            let user = (objectValue as? Comment)?.by,
            let userDetailsPopoverViewController = userDetailsPopover.contentViewController
                as? UserDetailsPopoverViewController
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
    static let toggleCommentRepliesNotification =
        Notification
        .Name("ToggleCommentRepliesNotification")
    static let goToParentCommentNotification = Notification.Name("GoToParentCommentNotification")
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let commentCell = NSUserInterfaceItemIdentifier("CommentCell")
}
