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

    override var isOpaque: Bool {
        return true
    }

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
        let margin: CGFloat = 10.0,
            height: CGFloat = 1.0,
            start: CGFloat = isSelected ? 0 : margin,
            width: CGFloat = isSelected ? bounds.maxX : bounds.maxX - (margin * 2),
            bottomRect = NSRect(
                x: start,
                y: 0,
                width: width,
                height: height
            ),
            topRect = NSRect(
                x: start,
                y: bounds.maxY - height,
                width: width,
                height: height
            ),
            color = isSelected ? Themes.current.cellHighlightForegroundColor.blended(withFraction: 0.75, of: .white) : Themes.current.dividerColor

        color?.setFill()

        if isSelected {
            bottomRect.fill()
        }

        if !isNextRowSelected {
            topRect.fill()
        }
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let storyRow = NSUserInterfaceItemIdentifier("StoryRow")
}
