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
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var urlButton: ThemeableButton!
    @IBOutlet weak var authorDateTextField: NSTextField!
    @IBOutlet weak var votesCommentsStackView: NSStackView!
    @IBOutlet weak var votesImageView: NSImageView!
    @IBOutlet weak var votesTextField: NSTextField!
    @IBOutlet weak var commentsImageView: NSImageView!
    @IBOutlet weak var commentsTextField: NSTextField!
    @IBOutlet weak var titleURLSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleSubtitleSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftCellSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightCellSpacingConstraint: NSLayoutConstraint!

    // MARK: Properties
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            if backgroundStyle == .dark {
                titleTextField.textColor = Themes.current.cellHighlightForegroundColor
                authorDateTextField.textColor = Themes.current.cellHighlightForegroundColor
                votesImageView.tintImage(with: Themes.current.cellHighlightForegroundColor)
                votesTextField.textColor = Themes.current.cellHighlightForegroundColor
                commentsImageView.tintImage(with: Themes.current.cellHighlightForegroundColor)
                commentsTextField.textColor = Themes.current.cellHighlightForegroundColor
                urlButton.borderColor = Themes.current.dividerColor
                urlButton.textColor = Themes.current.cellHighlightForegroundColor
            } else {
                titleTextField.textColor = Themes.current.normalTextColor
                authorDateTextField.textColor = Themes.current.normalTextColor
                votesImageView.tintImage(with: Themes.current.normalTextColor)
                votesTextField.textColor = Themes.current.normalTextColor
                commentsImageView.tintImage(with: Themes.current.normalTextColor)
                commentsTextField.textColor = Themes.current.normalTextColor
                urlButton.borderColor = Themes.current.dividerColor
                urlButton.textColor = Themes.current.normalTextColor
            }
        }
    }

    // MARK: Methods
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

    func configureFor(_ story: Story) {
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
            votesTextField.stringValue = String(story.score - 1)
            votesTextField.toolTip = "\(story.score - 1) " + (story.score - 1 > 1 ? "votes" : "vote")
            commentsTextField.stringValue = String(story.descendants)
            commentsTextField.toolTip = "\(story.descendants) " + (story.descendants > 1 ? "comments" : "comment")
            votesCommentsStackView.isHidden = false
        } else {
            votesCommentsStackView.isHidden = true
        }

        objectValue = story
    }

    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let availableWidth = width - (leftCellSpacingConstraint.constant + rightCellSpacingConstraint.constant)

        titleTextField.preferredMaxLayoutWidth = availableWidth
        authorDateTextField.preferredMaxLayoutWidth = availableWidth

        return fittingSize.height
    }
}

// MARK: - Reusable
extension StoryCellView: Reusable {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("StoryCell")
}

// MARK: - NSLayoutConstraint.Priority
private extension NSLayoutConstraint.Priority {
    static let almostRequired = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.required.rawValue - 1.0)
    static let almostHigh = NSLayoutConstraint.Priority(NSLayoutConstraint.Priority.defaultHigh.rawValue - 1.0)
}
