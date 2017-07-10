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
    @IBOutlet weak var authorTextField: NSTextField!

    @IBOutlet weak var opBadgeView: LightColoredBadgeView!

    @IBOutlet weak var timeTextField: NSTextField!

    @IBOutlet weak var repliesStackView: NSStackView!

    @IBOutlet weak var repliesButton: DisclosureButtonView!

    @IBOutlet weak var repliesTextField: NSTextField!

    @IBOutlet weak var commentTextSeparator: HorizontalLineSeparatorView!

    @IBOutlet var commentTextView: CommentTextView! {
        didSet {
            commentTextView.backgroundColor = Themes.current.backgroundColor
            commentTextView.textColor = Themes.current.normalTextColor
        }
    }

    // MARK: Properties
    var isExpanded: Bool = true {
        didSet {
            //repliesTextField.isHidden = isExpanded
            repliesButton.isExpanded = isExpanded
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
        guard let user = (objectValue as? Comment)?.by,
            let userDetailsPopoverViewController = userDetailsPopover.contentViewController as? UserDetailsPopoverViewController else {
            return
        }

        userDetailsPopover.show(relativeTo: authorTextField.bounds, of: authorTextField, preferredEdge: .maxY)
        userDetailsPopoverViewController.getUserInfo(user)
    }

    // MARK: Methods
    func configureFor(_ comment: Comment, story: Story?) {
        timeTextField.stringValue = comment.time.timeIntervalString
        timeTextField.toolTip = comment.time.description(with: Locale.autoupdatingCurrent)
        timeTextField.textColor = Themes.current.secondaryTextColor

        guard !comment.deleted else {
            commentTextView.attributedStringValue = NSAttributedString()
            opBadgeView.isHidden = true
            authorTextField.isEnabled = false
            authorTextField.stringValue = "[deleted]"
            authorTextField.textColor = Themes.current.disabledTextColor
            timeTextField.textColor = Themes.current.disabledTextColor
            repliesStackView.isHidden = true
            return
        }

        authorTextField.stringValue = comment.by ?? "unknown"
        authorTextField.isEnabled = comment.by != nil
        authorTextField.textColor = Themes.current.primaryTextColor

        opBadgeView.isHidden = comment.by != story?.by

        repliesTextField.isHidden = isExpanded

        commentTextView.attributedStringValue = comment.text.parseMarkup() 
        commentTextView.setTextColor(
            Themes.current.normalTextColor,
            range: NSRange(0 ..< commentTextView.attributedString().length)
        )

        objectValue = comment
    }

    func heightForWidth(_ width: CGFloat) -> CGFloat {
        frame.size.width = width

        layoutSubtreeIfNeeded()

        return fittingSize.height
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let toggleCommentRepliesNotification = Notification.Name("ToggleCommentRepliesNotification")
}

// MARK: - NSPopover Delegate
extension CommentCellView: NSPopoverDelegate {}

// MARK: - Reusable
extension CommentCellView: Reusable {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("CommentCell")
}
