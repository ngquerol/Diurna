//
//  StoryRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/01/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryRowView: NSTableRowView {

    // MARK: Properties
    override var isNextRowSelected: Bool {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    // MARK: Methods
    override func drawSelection(in dirtyRect: NSRect) {
        guard selectionHighlightStyle != .none else { return }

        Themes.current.cellHighlightBackgroundColor.setFill()
        dirtyRect.fill()
    }

    override func drawSeparator(in _: NSRect) {
        let bottomRect = NSMakeRect(0, 0, bounds.maxX, 1.0),
            topRect = NSMakeRect(0, bounds.maxY - 1.0, bounds.maxX, 1.0)

        if isSelected {
            Themes.current.dividerColor.setFill()

            bottomRect.fill()
            topRect.fill()
        } else {
            Themes.current.dividerColor.setFill()

            if !isNextRowSelected {
                topRect.fill()
            }
        }
    }
}

// MARK: - Reusable
extension StoryRowView: Reusable {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("StoryRow")
}
