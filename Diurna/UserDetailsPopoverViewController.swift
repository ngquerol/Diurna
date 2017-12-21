//
//  UserDetailsPopoverViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class UserDetailsPopoverViewController: NSViewController, NetworkingAware {

    // MARK: Outlets
    @IBOutlet var contentStackView: NSStackView! {
        didSet {
            contentStackView.isHidden = true
        }
    }

    @IBOutlet var userProgressIndicator: NSProgressIndicator! {
        didSet {
            userProgressIndicator.startAnimation(self)
        }
    }

    @IBOutlet var createdTextField: NSTextField!

    @IBOutlet var karmaTextField: NSTextField!

    @IBOutlet var separatorBox: NSBox! {
        didSet {
            separatorBox.isHidden = true
        }
    }

    @IBOutlet var aboutScrollView: NSScrollView! {
        didSet {
            aboutScrollView.isHidden = true
        }
    }

    @IBOutlet var aboutTextView: NSTextView!

    // MARK: Methods
    func show(_ name: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }

            self.apiClient.fetchUser(with: name) { userResult in
                switch userResult {

                case let .success(user):
                    self.karmaTextField.integerValue = user.karma
                    self.createdTextField.objectValue = user.created
                    self.aboutTextView.attributedStringValue = user.about?.parseMarkup() ?? .empty
                    NSAnimationContext.runAnimationGroup({ _ in
                        self.userProgressIndicator.animator().stopAnimation(self)
                    }) {
                        NSAnimationContext.runAnimationGroup({ _ in
                            self.aboutScrollView.isHidden = self.aboutTextView.attributedStringValue.length == 0
                            self.separatorBox.isHidden = self.aboutScrollView.isHidden
                        }) {
                            NSAnimationContext.runAnimationGroup({ _ in
                                self.contentStackView.animator().isHidden = false
                            })
                        }
                    }

                case let .failure(error):
                    NSAlert(error: error).runModal()
                }
            }
        }
    }
}

// MARK: - NSNib.Name
extension NSNib.Name {
    static let userDetailsPopover = NSNib.Name("UserDetailsPopoverView")
}
