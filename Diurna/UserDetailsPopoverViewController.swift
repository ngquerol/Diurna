//
//  UserDetailsPopoverViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class UserDetailsPopoverViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet weak var contentStackView: NSStackView! {
        didSet {
            contentStackView.isHidden = true
        }
    }

    @IBOutlet weak var userProgressIndicator: NSProgressIndicator! {
        didSet {
            userProgressIndicator.startAnimation(self)
        }
    }

    @IBOutlet weak var createdTextField: NSTextField!
    @IBOutlet weak var karmaTextField: NSTextField!
    @IBOutlet weak var separatorBox: NSBox! {
        didSet {
            separatorBox.isHidden = true
        }
    }

    @IBOutlet var aboutTextField: NSTextField! {
        didSet {
            aboutTextField.isHidden = true
        }
    }

    @IBOutlet weak var aboutTextTrailingSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var aboutTextLeadingSpacingConstraint: NSLayoutConstraint!

    // MARK: Properties
    private let API = FirebaseAPIClient.sharedInstance

    // MARK: View Lifecycle
    override func viewWillLayout() {
        super.viewWillLayout()

        aboutTextField.preferredMaxLayoutWidth = contentStackView.bounds.width - (aboutTextLeadingSpacingConstraint.constant + aboutTextTrailingSpacingConstraint.constant)
    }

    // MARK: Methods
    func getUserInfo(_ name: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let `self` = self else { return }

            self.API.fetchUser(with: name) { userResult in

                switch userResult {
                case .success(let user):
                    self.karmaTextField.intValue = Int32(user.karma)
                    self.createdTextField.objectValue = user.created
                    self.aboutTextField.attributedStringValue = user.about?.parseMarkup() ?? NSAttributedString()

                    NSAnimationContext.beginGrouping()
                    self.userProgressIndicator.animator().stopAnimation(self)
                    NSAnimationContext.current.completionHandler = {
                        NSAnimationContext.beginGrouping()
                        self.contentStackView.animator().isHidden = false
                        NSAnimationContext.endGrouping()
                        NSAnimationContext.current.completionHandler = {
                            NSAnimationContext.beginGrouping()
                            NSAnimationContext.current.allowsImplicitAnimation = true
                            self.aboutTextField.isHidden = (user.about == nil)
                            self.separatorBox.isHidden = self.aboutTextField.isHidden
                            NSAnimationContext.endGrouping()
                        }
                    }
                    NSAnimationContext.endGrouping()

                case .failure(let error):
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
