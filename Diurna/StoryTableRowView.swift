//
//  StoryTableRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 02/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryTableRowView : NSTableRowView {

    override func drawSelectionInRect(dirtyRect: NSRect) {
        super.drawSelectionInRect(dirtyRect)

        let selectedColor = NSColor.selectedControlColor()
        let normalColor = NSColor.controlTextColor()

        if selected {
            if emphasized {
                selectedColor.set()
            } else {
                normalColor.set()
            }
        }
    }
}
