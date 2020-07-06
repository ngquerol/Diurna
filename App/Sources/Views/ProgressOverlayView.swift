//
//  ProgressOverlayView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 10/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class ProgressOverlayView: NSView {
    // MARK: Outlets

    @IBOutlet var view: NSView!

    @IBOutlet var stackView: NSStackView!

    @IBOutlet var messageTextField: NSTextField!

    @IBOutlet var progressIndicator: NSProgressIndicator!

    // MARK: Initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    private func commonInit(frame frameRect: NSRect? = nil) {
        Bundle.main.loadNibNamed(
            .progressOverlayView,
            owner: self,
            topLevelObjects: nil
        )
        addSubview(view)
        view.frame = frameRect ?? bounds
    }

    // MARK: View lifecycle

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        progressIndicator.startAnimation(self)
    }
}

// MARK: - NSNib.Name

extension NSNib.Name {
    static let progressOverlayView = "ProgressOverlayView"
}
