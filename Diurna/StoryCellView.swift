//
//  StoryTableCell.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 20/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryCellView: NSTableCellView {

    // MARK: Outlets
    @IBOutlet var contentView: NSTableCellView! {
        didSet {
            contentView.frame = bounds
            contentView.autoresizingMask = [.viewHeightSizable, .viewWidthSizable]
            addSubview(contentView)
        }
    }
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var urlButton: NSButton!
    @IBOutlet weak var authorDateTextField: NSTextField!
    @IBOutlet weak var votesCommentsStackView: NSStackView!
    @IBOutlet weak var votesImageView: NSImageView! {
        didSet {
            //votesImageView.tintImage(with: .orange)
        }
    }
    @IBOutlet weak var votesTextField: NSTextField!
    @IBOutlet weak var commentsImageView: NSImageView! {
        didSet {
            //commentsImageView.tintImage(with: .orange)
        }
    }
    @IBOutlet weak var commentsTextField: NSTextField!
    @IBOutlet weak var cellSeparator: NSBox!
    @IBOutlet weak var titleButtonSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleSubtitleSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftCellSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightCellSpacingConstraint: NSLayoutConstraint!

    // MARK: Properties
    static let reuseIdentifier = "StoryCell"

    override var backgroundStyle: NSBackgroundStyle {
        didSet {
            if backgroundStyle == .dark {
                titleTextField.textColor = .white
                authorDateTextField.textColor = .white
                votesImageView.tintImage(with: .white)
                votesTextField.textColor = .white
                commentsImageView.tintImage(with: .white)
                commentsTextField.textColor = .white
                cellSeparator.isHidden = true
            } else {
                titleTextField.textColor = .black
                authorDateTextField.textColor = .secondaryLabelColor
                votesImageView.tintImage(with: .black)
                votesTextField.textColor = .secondaryLabelColor
                commentsImageView.tintImage(with: .black)
                commentsTextField.textColor = .secondaryLabelColor
                cellSeparator.isHidden = false
            }
        }
    }

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonSetup()
    }

    private func commonSetup() {
        Bundle.main.loadNibNamed("StoryCellView", owner: self, topLevelObjects: nil)

        identifier = StoryCellView.reuseIdentifier
    }

    // MARK: Methods
    func configureFor(_ story: Story) {
        titleTextField.stringValue = story.title

        if let URL = story.url, let shortURL = URL.shortURL {
            urlButton.title = shortURL
            urlButton.toolTip = URL.absoluteString
            urlButton.isHidden = false
            titleButtonSpacingConstraint.priority = NSLayoutPriorityRequired - 1.0
            titleSubtitleSpacingConstraint.priority = NSLayoutPriorityDefaultHigh
        } else {
            urlButton.isHidden = true
            titleButtonSpacingConstraint.priority = NSLayoutPriorityDefaultHigh
            titleSubtitleSpacingConstraint.priority = NSLayoutPriorityRequired - 1.0
        }

        authorDateTextField.stringValue = "by \(story.by), \(story.time.timeIntervalString)"

        if story.type != "job" {
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

        return contentView.fittingSize.height
    }

    @IBAction private func visitURL(_ sender: NSButton) {
        guard let story = objectValue as? Story,
            story.url != nil,
            let url = story.url else {
                return
        }

        do {
            try NSWorkspace.shared().open(url, options: .withoutActivation, configuration: [String: Any]())
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
    }
}
