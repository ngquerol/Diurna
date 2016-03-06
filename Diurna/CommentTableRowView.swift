//
//  CommentTableRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentTableRowView: NSTableRowView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        guard let cellView = viewAtColumn(0) else {
            return
        }

        let cellXOrigin = cellView.frame.origin.x
        var pos: CGFloat = 10
        var alpha: CGFloat = 0.5

        while pos < cellXOrigin {
            let line = NSBezierPath()
            line.lineWidth = 1.0
            NSColor.gridColor().colorWithAlphaComponent(alpha).setStroke()

            line.moveToPoint(NSPoint(x: pos, y: NSMaxY(self.bounds)))
            line.lineToPoint(NSPoint(x: pos, y: NSMinY(self.bounds)))
            line.stroke()

            pos += 20
            alpha -= 0.1
        }
    }
}