//
//  StoryStatusView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 10/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryStatusView: NSView {

    // MARK: Outlets

    @IBOutlet var view: NSView!

    @IBOutlet var scoreImageView: NSImageView!

    @IBOutlet var scoreTextField: NSTextField!

    @IBOutlet var commentsImageView: NSImageView!

    @IBOutlet var commentsTextField: NSTextField!

    // MARK: Properties

    var score: Int = 0 {
        didSet {
            scoreTextField.stringValue = score.kFormatted
        }
    }

    var comments: Int = 0 {
        didSet {
            commentsTextField.stringValue = comments.kFormatted
        }
    }

    var imageTint: NSColor = Themes.current.normalTextColor {
        didSet {
            scoreImageView.tintImage(with: imageTint)
            commentsImageView.tintImage(with: imageTint)
        }
    }

    var textColor: NSColor = Themes.current.secondaryTextColor {
        didSet {
            scoreTextField.textColor = textColor
            commentsTextField.textColor = textColor
        }
    }

    // MARK: Initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        Bundle.main.loadNibNamed(
            .storyStatusView,
            owner: self,
            topLevelObjects: nil
        )
        addSubview(view)
        view.frame = bounds
    }
}

// MARK: - NSNib.Name

private extension NSNib.Name {
    static let storyStatusView = "StoryStatusView"
}
