//
//  StoryCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 20/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class StoryCellView: NSTableCellView {
    // MARK: Outlets

    @IBOutlet var containerStackView: NSStackView!

    @IBOutlet var titleTextField: NSTextField!

    @IBOutlet var urlButton: NSButton!

    @IBOutlet var authorDateTextField: NSTextField!

    @IBOutlet var storyStatusView: StoryStatusView!

    // MARK: Properties

    override var objectValue: Any? {
        didSet {
            guard let story = objectValue as? Story else {
                return
            }

            titleTextField.stringValue = story.title

            if let URL = story.url, let shortURL = URL.shortURL {
                urlButton.title = shortURL
                urlButton.toolTip = URL.absoluteString
                urlButton.isHidden = false
            } else {
                urlButton.isHidden = true
            }

            authorDateTextField.stringValue = "by \(story.by), \(story.time.timeIntervalString)"

            if story.type == .story {
                storyStatusView.score = story.score - 1
                storyStatusView.comments = story.descendants ?? 0
                storyStatusView.isHidden = false
            } else {
                storyStatusView.isHidden = true
            }
        }
    }

    // MARK: Methods

    override func layout() {
        super.layout()

        titleTextField.preferredMaxLayoutWidth =
            containerStackView.frame.width
            - (containerStackView.edgeInsets.left + containerStackView.edgeInsets.right)

        needsLayout = true
    }

    @IBAction private func visitURL(_: NSButton) {
        guard let story = objectValue as? Story,
            story.url != nil,
            let url = story.url
        else {
            return
        }

        do {
            try NSWorkspace.shared.open(url, options: .withoutActivation, configuration: [:])
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let storyCell = NSUserInterfaceItemIdentifier("StoryCell")
}
