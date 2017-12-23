//
//  StoryCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 20/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryCellView: NSTableCellView {

    // MARK: Outlets

    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var urlButton: ThemeableButton!
    @IBOutlet var authorDateTextField: NSTextField!
    @IBOutlet var storyStatusView: StoryStatusView!
    @IBOutlet var titleURLSpacingConstraint: NSLayoutConstraint!
    @IBOutlet var titleSubtitleSpacingConstraint: NSLayoutConstraint!
    @IBOutlet var leftCellSpacingConstraint: NSLayoutConstraint!
    @IBOutlet var rightCellSpacingConstraint: NSLayoutConstraint!

    // MARK: Properties

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            if backgroundStyle == .dark {
                titleTextField.textColor = Themes.current.cellHighlightForegroundColor
                authorDateTextField.textColor = Themes.current.cellHighlightForegroundColor
                urlButton.borderColor = Themes.current.cellHighlightForegroundColor.blended(withFraction: 0.75, of: .white)!
                urlButton.textColor = Themes.current.cellHighlightForegroundColor
            } else {
                titleTextField.textColor = Themes.current.normalTextColor
                authorDateTextField.textColor = Themes.current.normalTextColor
                urlButton.borderColor = Themes.current.dividerColor
                urlButton.textColor = Themes.current.normalTextColor
            }
        }
    }

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
                titleURLSpacingConstraint.priority = .almostRequired
                titleSubtitleSpacingConstraint.priority = .defaultHigh
            } else {
                urlButton.isHidden = true
                titleURLSpacingConstraint.priority = .defaultHigh
                titleSubtitleSpacingConstraint.priority = .almostRequired
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

        titleTextField.preferredMaxLayoutWidth = titleTextField.frame.size.width

        super.layout()
    }

    @IBAction private func visitURL(_: NSButton) {
        guard let story = objectValue as? Story,
            story.url != nil,
            let url = story.url else {
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

// MARK: - NSLayoutConstraint.Priority

private extension NSLayoutConstraint.Priority {
    static let almostRequired = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.required.rawValue - 1.0)
    static let almostHigh = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultHigh.rawValue - 1.0)
}
