//
//  CategoryTableRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 19/05/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CategoryTableRowView: NSTableRowView {

    override var selected: Bool {
        didSet {
            needsDisplay = true
        }
    }

    override func drawBackgroundInRect(dirtyRect: NSRect) {
        guard let cellView = viewAtColumn(0) as? NSTableCellView else {
            return
        }

        let cgContext = NSGraphicsContext.currentContext()!.CGContext

        if !selected {
            CGContextSetFillColorWithColor(cgContext, NSColor.clearColor().CGColor)
            cellView.textField?.textColor = NSColor.whiteColor()
        } else {
            CGContextSetFillColorWithColor(cgContext, NSColor.whiteColor().CGColor)
            cellView.textField?.textColor = NSColor.tertiaryLabelColor()
        }

        CGContextFillRect(cgContext, dirtyRect)
    }
}
