//
//  AboutViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/05/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class AboutViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet var iconImageView: NSImageView!

    @IBOutlet var nameTextField: NSTextField!

    @IBOutlet var versionTextField: NSTextField!

    @IBOutlet var creditsTextView: SelfSizingTextView!

    @IBOutlet var copyrightTextField: NSTextField!

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        iconImageView.image = NSApp.applicationIconImage

        loadBundleInfo()
        loadCredits()
    }

    // MARK: Methods

    private func loadBundleInfo() {
        guard let info = Bundle.main.infoDictionary else { return }

        let bundleName = info["CFBundleName"] as? String ?? "Diurna"
        let bundleVersion = info["CFBundleShortVersionString"] as? String ?? "?"
        let bundleBuild = info["CFBundleVersion"] as? String ?? "?"
        let copyright =
            info["NSHumanReadableCopyright"] as? String
            ?? "© 2016-present Nicolas Gaulard-Querol, all rights reserved"

        nameTextField.stringValue = bundleName
        versionTextField.stringValue = "Version \(bundleVersion) (\(bundleBuild))"
        copyrightTextField.stringValue = copyright
    }

    private func loadCredits() {
        guard let creditsFileURL = Bundle.main.url(forResource: "Credits", withExtension: "rtf")
        else {
            return
        }

        if let creditsText = try? NSAttributedString(
            url: creditsFileURL,
            options: [
                NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString
                    .DocumentType.rtf
            ],
            documentAttributes: nil
        ) {
            creditsTextView.attributedStringValue = creditsText
        }
    }
}
