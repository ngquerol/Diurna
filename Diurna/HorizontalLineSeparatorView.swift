//
//  HorizontalLineSeparatorView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 04/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable class HorizontalLineSeparatorView: NSView {

    // MARK: Properties

    @IBInspectable var separatorThickness: CGFloat = 1.0

    @IBInspectable var leftInset: CGFloat = 0.0

    @IBInspectable var rightInset: CGFloat = 0.0

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: separatorThickness)
    }

    // MARK: Methods

    override func draw(_ dirtyRect: NSRect) {
        Themes.current.dividerColor.set()

        let drawingRect = NSRect(x: leftInset,
                                 y: dirtyRect.midY - (separatorThickness / 2),
                                 width: dirtyRect.width - (leftInset + rightInset),
                                 height: separatorThickness)

        drawingRect.fill()
    }
}
