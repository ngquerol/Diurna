//
//  HorizontalLineSeparatorView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 04/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable
class HorizontalLineSeparatorView: NSView {

    @IBInspectable var separatorColor: NSColor = .gridColor
    @IBInspectable var separatorThickness: CGFloat = 1.0
    @IBInspectable var leftInset: CGFloat = 0.0
    @IBInspectable var rightInset: CGFloat = 0.0

    override var intrinsicContentSize: NSSize {
        get {
            return NSSize(width: NSViewNoIntrinsicMetric, height: separatorThickness)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        separatorColor.set()
        
        NSRectFill(
            NSRect(x: leftInset,
                   y: NSMidY(dirtyRect) - (separatorThickness / 2),
                   width: NSWidth(dirtyRect) - (leftInset + rightInset),
                   height: separatorThickness)
        )
    }
}
