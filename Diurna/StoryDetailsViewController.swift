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

    @IBOutlet var storyStatusView: StoryStatusView!

    @IBOutlet var storyStatusBottomSpacingConstraint: NSLayoutConstraint!

    @IBOutlet var storyStatusContentSpacingConstraint: NSLayoutConstraint!

    @IBOutlet var contentTextField: NSTextField!

    @IBOutlet var contentTextFieldMaxHeightConstraint: NSLayoutConstraint!

    @IBOutlet var contentDisclosureButton: DisclosureButtonView! {
        didSet {
            contentDisclosureButton.isExpanded = true
        }
    }

    // MARK: Properties

    var selectedStory: Story? {
        didSet {
            guard let story = selectedStory else {
                return
            }

            updateViews(with: story)
        }
    }

    private let storyContentCollapsedHeight: CGFloat = 0

    private let storyContentExpandedHeight: CGFloat = 150

    // MARK: View lifecycle

    override func viewDidLayout() {
        super.viewDidLayout()

        let availableWidth = view.bounds.width - (titleLeadingSpaceConstraint.constant + titleTrailingSpaceConstraint.constant)

        titleTextField.preferredMaxLayoutWidth = availableWidth
        contentTextField.preferredMaxLayoutWidth = availableWidth
    }

    @IBAction func userDidToggleDescription(_: Any) {
        NSAnimationContext.runAnimationGroup({ context in
            context.allowsImplicitAnimation = true
            context.duration = 0.25
            contentTextFieldMaxHeightConstraint.constant = contentDisclosureButton.isExpanded ? storyContentExpandedHeight : storyContentCollapsedHeight
            contentTextField.isHidden = !contentDisclosureButton.isExpanded
        })
    }

    // MARK: Methods

    private func updateViews(with story: Story) {
        titleTextField.stringValue = story.title
        titleTextField.toolTip = story.title
        titleTextField.isHidden = false

        detailsTextField.stringValue = "by \(story.by), \(story.time.timeIntervalString)"

        storyStatusView.score = story.score - 1
        storyStatusView.comments = story.descendants ?? 0

        // TODO: height of content based on string height, with max

        if let storyText = story.text?.parseMarkup() {
            contentTextField.attributedStringValue = storyText
            contentTextField.isHidden = false
            contentDisclosureButton.isHidden = false

            storyStatusContentSpacingConstraint.priority = .defaultHigh
            storyStatusBottomSpacingConstraint.priority = .defaultLow
        } else {
            contentTextField.attributedStringValue = .empty
            contentTextField.isHidden = true
            contentDisclosureButton.isHidden = true

            storyStatusContentSpacingConstraint.priority = .defaultLow
            storyStatusBottomSpacingConstraint.priority = .defaultHigh
        }
    }
}
