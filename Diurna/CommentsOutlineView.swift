//
//  CommentsOutlineView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 25/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentsOutlineView: NSOutlineView {

    // Don't show the disclosure triangle
    override func frameOfOutlineCellAtRow(row: Int) -> NSRect {
        return NSZeroRect
    }

    // Get back the space reserved for the disclosure cell
    override func frameOfCellAtColumn(column: Int, row: Int) -> NSRect {
        var frame = super.frameOfCellAtColumn(column, row: row)

        frame.origin.x -= self.indentationPerLevel
        frame.size.width += self.indentationPerLevel

        return frame
    }
}
