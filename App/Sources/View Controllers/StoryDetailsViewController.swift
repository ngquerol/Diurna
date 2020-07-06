//
//  StoryDetailsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/11/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class StoryDetailsViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet var titleTextField: NSTextField!

    @IBOutlet var detailsTextField: NSTextField!

    @IBOutlet var statusView: StoryStatusView!

    @IBOutlet var contentDisclosureButton: NSButton! {
        didSet {
            contentDisclosureButton.isHidden = true
        }
    }

    @IBOutlet var contentScrollView: NSScrollView! {
        didSet {
            contentScrollView.isHidden = true
        }
    }

    @IBOutlet var contentScrollViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var contentTextView: SelfSizingTextView!

    // MARK: Properties

    override var representedObject: Any? {
        didSet {
            if let story = representedObject as? Story {
                updateViews(with: story)
            }
        }
    }

    private let maximumTextHeight: CGFloat = 150.0

    private var isContentExpanded: Bool = true

    private var textHeight: CGFloat {
        let textHeight = isContentExpanded ? contentTextView.fittingSize.height : 0,
            totalTextHeight =
                textHeight
                // account for the eventual top/bottom insets
                + contentScrollView.contentInsets.top
                + contentScrollView.contentInsets.bottom
                // account for the eventual top/bottom borders
                + (contentScrollView.borderType == .noBorder ? 0 : 4)

        return min(totalTextHeight, maximumTextHeight)
    }

    // MARK: Actions

    @IBAction func userDidToggleDescription(_: Any) {
        isContentExpanded.toggle()

        animateTextHeightConstraint()
    }

    // MARK: Methods

    private func updateViews(with story: Story) {
        titleTextField.stringValue = story.title
        titleTextField.toolTip = story.title
        titleTextField.isHidden = false

        detailsTextField.stringValue = "by \(story.by), \(story.time.timeIntervalString)"
        detailsTextField.toolTip = story.time.description(with: .autoupdatingCurrent)

        statusView.score = story.score - 1
        statusView.comments = story.descendants ?? 0

        if let text = story.text?.parseMarkup() {
            contentTextView.attributedStringValue = text
            contentScrollView.isHidden = false
            contentDisclosureButton.isHidden = false
        } else {
            contentTextView.attributedStringValue = .empty
            contentScrollView.isHidden = true
            contentDisclosureButton.isHidden = true
        }

        contentScrollViewHeightConstraint.constant = textHeight
    }

    private func animateTextHeightConstraint() {
        if isContentExpanded {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                contentScrollView.animator().isHidden = false
                contentScrollViewHeightConstraint.animator().constant = textHeight
            }
        } else {
            NSAnimationContext.runAnimationGroup(
                { context in
                    context.duration = 0.25
                    contentScrollViewHeightConstraint.animator().constant = textHeight
                },
                completionHandler: {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.25
                        self.contentScrollView.animator().isHidden = true
                    }
                })
        }
    }
}
