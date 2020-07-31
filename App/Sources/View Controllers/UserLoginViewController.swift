//
//  UserLoginViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 29/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI
import OSLog

// MARK: - UserLoginViewControllerDelegate

@objc protocol UserLoginViewControllerDelegate: class {
    func userDidLogin(with user: String)

    func userDidCancelLogin()
}

// MARK: - UserLoginViewController

class UserLoginViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet weak var userNameTextField: NSTextField! {
        didSet {
            userNameTextField.delegate = self
        }
    }

    @IBOutlet weak var userPasswordTextField: NSSecureTextField! {
        didSet {
            userPasswordTextField.delegate = self
        }
    }

    @IBOutlet weak var cancelButton: NSButton! {
        didSet {
            cancelButton.action = #selector(self.cancel(_:))
        }
    }

    @IBOutlet weak var loginButton: NSButton! {
        didSet {
            loginButton.isEnabled = false
            loginButton.action = #selector(self.login(_:))
        }
    }

    // MARK: Properties

    weak var delegate: UserLoginViewControllerDelegate?

    var progressOverlayView: NSView?

    // MARK: Methods

    @objc private func login(_ sender: Any?) {
        showProgressOverlay(
            with: "Logging in as \"\(userNameTextField.stringValue)\"…"
        )

        webClient.login(
            withAccount: userNameTextField.stringValue,
            andPassword: userPasswordTextField.stringValue
        ) { [weak self] loginResult in
            switch loginResult {
            case let .success(user):
                self?.delegate?.userDidLogin(with: user)
            case let .failure(error):
                self?.handleError(error)
            }

            self?.hideProgressOverlay()
        }
    }

    @objc private func cancel(_ sender: Any?) {
        delegate?.userDidCancelLogin()
    }

    private func handleError(_ error: Error) {
        os_log(
            "Failed to authenticate user \"%s\": %s",
            log: .webRequests,
            type: .error,
            userNameTextField.stringValue,
            error.localizedDescription
        )

        NSAlert.showModal(
            withTitle: "Failed to log in",
            andText: """
                You may need to verify your login using a captcha;
                For now this is unsupported.
                """
        )
    }
}

// MARK: - NSNib.Name

extension NSNib.Name {
    static let userLoginViewController = "UserLoginViewController"
}

// MARK: - NSTextFieldDelegate

extension UserLoginViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        func isNotBlank(_ string: String) -> Bool {
            string.trimmingCharacters(in: .whitespaces).count > 0
        }

        let inputs = [
            userNameTextField.stringValue,
            userPasswordTextField.stringValue,
        ]

        loginButton.isEnabled = inputs.allSatisfy(isNotBlank)
    }
}

// MARK: - HNWebConsumer

extension UserLoginViewController: HNWebConsumer {}

// MARK: - ProgressShowing

extension UserLoginViewController: ProgressShowing {}
