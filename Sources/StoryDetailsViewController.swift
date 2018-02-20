//
//  StoryDetailsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/11/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryDetailsViewController: NSViewController {

    // MARK: Outlets

    @IBOutlet var titleTextField: NSTextField! {
        didSet {
            titleTextField.backgroundColor = Themes.current.backgroundColor
            titleTextField.textColor = Themes.current.normalTextColor
            titleTextField.isHidden = true
        }
    }

    @IBOutlet var titleLeadingSpaceConstraint: NSLayoutConstraint!

    @IBOutlet var titleTrailingSpaceConstraint: NSLayoutConstraint!

    @IBOutlet var detailsTextField: NSTextField! {
        didSet {
            detailsTextField.textColor = Themes.current.secondaryTextColor
        }
    }

    @IBOutlet var statusView: StoryStatusView!

    @IBOutlet var bottomSpacingConstraint: NSLayoutConstraint!

    @IBOutlet var contentSpacingConstraint: NSLayoutConstraint!

    @IBOutlet var contentScrollView: FadingScrollView!

    @IBOutlet var contentScrollViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var contentTextView: SelfSizingTextView!

    @IBOutlet var contentDisclosureButton: DisclosureButtonView!

    // MARK: Properties

    var selectedStory: Story? {
        didSet {
            guard let story = selectedStory else {
                return
            }

            updateViews(with: story)
        }
    }

    // MARK: View lifecycle

    override func viewDidLayout() {
        super.viewDidLayout()

        let availableWidth = view.bounds.width - (titleLeadingSpaceConstraint.constant + titleTrailingSpaceConstraint.constant)

        titleTextField.preferredMaxLayoutWidth = availableWidth
    }

    @IBAction func userDidToggleDescription(_: Any) {
        if contentDisclosureButton.isExpanded {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                contentScrollViewHeightConstraint.animator().constant = contentTextView.fittingSize.height
                contentScrollView.animator().isHidden = !self.contentDisclosureButton.isExpanded
            })
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                contentScrollView.animator().isHidden = !contentDisclosureButton.isExpanded
                contentScrollViewHeightConstraint.animator().constant = 0
            })
        }
    }

    // MARK: Methods

    private func updateViews(with story: Story) {
        titleTextField.stringValue = story.title
        titleTextField.toolTip = story.title
        titleTextField.isHidden = false

        detailsTextField.stringValue = "by \(story.by), \(story.time.timeIntervalString)"

        statusView.score = story.score - 1
        statusView.comments = story.descendants ?? 0

        if let text = story.text?.parseMarkup() {
            contentTextView.attributedStringValue = text
            contentScrollView.isHidden = false
            contentDisclosureButton.isHidden = false

            contentSpacingConstraint.priority = .defaultHigh
            bottomSpacingConstraint.priority = .defaultLow
        } else {
            contentTextView.attributedStringValue = .empty
            contentScrollView.isHidden = true
            contentDisclosureButton.isHidden = true

            contentSpacingConstraint.priority = .defaultLow
            bottomSpacingConstraint.priority = .defaultHigh
        }

        contentScrollViewHeightConstraint.constant = contentDisclosureButton.isExpanded ? contentTextView.fittingSize.height : 0
    }
}
