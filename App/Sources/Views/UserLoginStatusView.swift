//
//  UserLoginStatusView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

// MARK: - UserLoginStatusViewDelegate

@objc protocol UserLoginStatusViewDelegate: class {

    func userDidRequestLogin()

    func userDidRequestLogout()
}

// MARK: - UserLoginStatusView

class UserLoginStatusView: NSView {

    // MARK: Outlets

    @IBOutlet var view: NSView!

    @IBOutlet var userButton: NSPopUpButton!

    @IBOutlet var userMenu: NSMenu!

    @IBOutlet var userStatusIndicator: NSImageView!

    // MARK: Properties

    weak var delegate: UserLoginStatusViewDelegate?

    var user: String? {
        didSet {
            updateButton()
            updateStatusIndicator()
        }
    }

    // MARK: Initializers

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit(frame frameRect: NSRect? = nil) {
        Bundle.main.loadNibNamed(
            .userLoginStatusView,
            owner: self,
            topLevelObjects: nil
        )
        addSubview(view)
        view.frame = frameRect ?? bounds
    }

    private func updateButton() {
        userMenu.removeAllItems()

        if let user = user {
            userMenu.addItem(withTitle: user, action: nil, keyEquivalent: "")
            userMenu.addItem(
                withTitle: "Log out",
                action: #selector(delegate?.userDidRequestLogout),
                keyEquivalent: ""
            )
        } else {
            userMenu.addItem(withTitle: "Logged out", action: nil, keyEquivalent: "")
            userMenu.addItem(
                withTitle: "Log in",
                action: #selector(delegate?.userDidRequestLogin),
                keyEquivalent: ""
            )
        }
    }

    private func updateStatusIndicator() {
        if let user = user {
            userStatusIndicator.animator().image = NSImage(named: NSImage.statusAvailableName)
            userStatusIndicator.toolTip = "Logged in as \(user)"
        } else {
            userStatusIndicator.animator().image = NSImage(named: NSImage.statusNoneName)
            userStatusIndicator.toolTip = "Logged out"
        }
    }
}

// MARK: - NSNib.Name

extension NSNib.Name {
    fileprivate static let userLoginStatusView = "UserLoginStatusView"
}
