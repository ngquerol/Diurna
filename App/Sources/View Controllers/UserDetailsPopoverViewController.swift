//
//  UserDetailsPopoverViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class UserDetailsPopoverViewController: NSViewController {
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

    @IBOutlet var usernameTextField: NSTextField! {
        didSet {
            usernameTextField.isHidden = true
        }
    }

    @IBOutlet var usernameSeparator: NSBox! {
        didSet {
            usernameSeparator.isHidden = true
        }
    }

    @IBOutlet var createdTextField: NSTextField!

    @IBOutlet var karmaTextField: NSTextField!

    @IBOutlet var descriptionSeparator: NSBox! {
        didSet {
            descriptionSeparator.isHidden = true
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
            guard let self = self else { return }

            self.apiClient.fetchUser(with: name) { userResult in
                switch userResult {
                case let .success(user):
                    self.usernameTextField.stringValue = user.id
                    self.karmaTextField.integerValue = user.karma
                    self.createdTextField.objectValue = user.created
                    self.aboutTextView.attributedStringValue = user.about?.parseMarkup() ?? .empty
                    NSAnimationContext.runAnimationGroup(
                        { _ in
                            self.userProgressIndicator.animator().stopAnimation(self)
                        }
                    ) {
                        NSAnimationContext.runAnimationGroup(
                            { _ in
                                self.aboutScrollView.isHidden =
                                    self.aboutTextView
                                    .attributedStringValue.length == 0
                                self.descriptionSeparator.isHidden = self.aboutScrollView.isHidden
                            }
                        ) {
                            NSAnimationContext.runAnimationGroup { _ in
                                self.contentStackView.animator().isHidden = false
                            }
                        }
                    }

                case let .failure(error):
                    NSAlert(error: error).runModal()
                }
            }
        }
    }
}

// MARK: - HNAPIConsumer

extension UserDetailsPopoverViewController: HNAPIConsumer {}

// MARK: - NSNib.Name

extension NSNib.Name {
    static let userDetailsPopover = "UserDetailsPopoverView"
}

// MARK: - NSPopover Delegate

extension UserDetailsPopoverViewController: NSPopoverDelegate {
    func popoverShouldDetach(_: NSPopover) -> Bool {
        return true
    }

    func popoverDidDetach(_: NSPopover) {
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = true
            usernameTextField.isHidden = false
            usernameSeparator.isHidden = false
        }
    }
}
