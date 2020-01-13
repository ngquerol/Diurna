//
//  ProgressOverlayView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 10/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class ProgressOverlayView: NSView {

    // MARK: Outlets

    @IBOutlet var view: NSView!

    @IBOutlet var progressStackView: NSStackView!

    @IBOutlet var progressMessage: NSTextField!

    @IBOutlet var progressIndicator: NSProgressIndicator!

    // MARK: Initializers

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        Bundle.main.loadNibNamed(
            .progressOverlayView,
            owner: self,
            topLevelObjects: nil
        )
        addSubview(view)
        view.frame = bounds
    }
}

// MARK: - NSNib.Name

private extension NSNib.Name {
    static let progressOverlayView = "ProgressOverlayView"
}
