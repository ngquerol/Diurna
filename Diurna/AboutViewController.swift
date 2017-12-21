//
//  AboutViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/05/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet weak var iconImageView: NSImageView!

    @IBOutlet weak var nameTextField: NSTextField!

    @IBOutlet weak var versionTextField: NSTextField!

    @IBOutlet var creditsTextView: NSTextView!
    
    @IBOutlet weak var copyrightTextField: NSTextField!

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

        let bundleName = info["CFBundleName"] as? String ?? "Diurna",
            bundleVersion = info["CFBundleShortVersionString"] as? String ?? "?",
            bundleBuild = info["CFBundleVersion"] as? String ?? "?",
            copyright = info["NSHumanReadableCopyright"] as? String ?? "© 2017 Nicolas Gaulard-Querol, all rights reserved"

        nameTextField.stringValue = bundleName
        versionTextField.stringValue = "Version \(bundleVersion) (\(bundleBuild))"
        copyrightTextField.stringValue = copyright
    }

    private func loadCredits() {
        guard let creditsFileURL = Bundle.main.url(forResource: "Credits", withExtension: "rtf") else {
            return
        }

        if let creditsText = try? NSAttributedString(
            url: creditsFileURL,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) {
            creditsTextView.attributedStringValue = creditsText
        }
    }
}
