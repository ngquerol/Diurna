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
    @IBOutlet var contentView: NSTableCellView! {
        didSet {
            contentView.frame = bounds
            contentView.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
            addSubview(contentView)
        }
    }
    @IBOutlet weak var mainContainerView: NSView!
    @IBOutlet weak var authorTextField: ClickableTextField!
    @IBOutlet weak var opBadgeView: BadgeView!
    @IBOutlet weak var timeTextField: NSTextField!
    @IBOutlet weak var repliesStackView: NSStackView!
    @IBOutlet weak var repliesButton: DisclosureButtonView!
    @IBOutlet weak var repliesTextField: NSTextField!
    @IBOutlet weak var commentTextSeparator: HorizontalLineSeparatorView!
    @IBOutlet var commentTextView: CommentTextView!

    // MARK: Properties
    static let reuseIdentifier = "CommentCell"

    var isCollapsed: Bool = true {
        didSet {
            repliesButton.isCollapsed = oldValue
        }
    }

    private var bgColor: NSColor = .white
    private var borderWidth: CGFloat = 1.0
    private var cornerRadius: CGFloat = 2.0
    private var borderColor: NSColor = .quaternaryLabelColor
    private var hasShadow: Bool = true
    private var shadowColor: NSColor = .tertiaryLabelColor

    private lazy var userDetailsPopover: NSPopover = {
        let userDetailsPopoverViewController = UserDetailsPopoverViewController(nibName: "UserDetailsPopoverView", bundle: nil),
            popover = NSPopover()

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = userDetailsPopoverViewController

        return popover
    }()

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    private func commonSetup() {
        Bundle.main.loadNibNamed("CommentCellView", owner: self, topLevelObjects: nil)

        identifier = CommentCellView.reuseIdentifier
    }

    // MARK: Methods
    func configureFor(_ comment: Comment, story: Story?) {
        timeTextField.stringValue = comment.time.timeIntervalString
        timeTextField.toolTip = comment.time.description(with: Locale.current)

        guard !comment.deleted else {
            commentTextView.attributedStringValue = NSAttributedString()
            opBadgeView.isHidden = true
            authorTextField.stringValue = "[deleted]"
            authorTextField.textColor = .tertiaryLabelColor
            authorTextField.isEnabled = false
            timeTextField.textColor = .tertiaryLabelColor
            repliesStackView.isHidden = true
            return
        }

        repliesTextField.alphaValue = isCollapsed ? 1.0 : 0.0
        commentTextView.attributedStringValue = comment.text ?? NSAttributedString()
        opBadgeView.isHidden = comment.by != story?.by
        authorTextField.stringValue = comment.by ?? "unknown"
        authorTextField.textColor = .labelColor
        authorTextField.isEnabled = comment.by != nil
        timeTextField.textColor = .secondaryLabelColor

        objectValue = comment
    }

    func heightForWidth(_ width: CGFloat) -> CGFloat {
        contentView.frame.size.width = width

        layoutSubtreeIfNeeded()

        return contentView.fittingSize.height
    }

    @IBAction private func toggleReplies(_ sender: NSButton) {
        let toggleChildren = NSEvent.modifierFlags().contains(NSEventModifierFlags.option)

        NotificationCenter.default.post(
            name: .toggleCommentRepliesNotification,
            object: self,
            userInfo: [
                "toggleChildren": toggleChildren
            ]
        )
    }

    @IBAction private func showUserDetailsPopover(_ sender: NSTextField) {
        guard let user = (objectValue as? Comment)?.by,
            let userDetailsPopoverViewController = userDetailsPopover.contentViewController as? UserDetailsPopoverViewController else {
            return
        }

        userDetailsPopover.show(relativeTo: authorTextField.bounds, of: authorTextField, preferredEdge: .maxY)
        userDetailsPopoverViewController.getUserInfo(user)
    }
}

// MARK: Notifications
extension Notification.Name {
    static let toggleCommentRepliesNotification = Notification.Name("ToggleCommentRepliesNotification")
}

// MARK: Popover Delegate
extension CommentCellView: NSPopoverDelegate { }
