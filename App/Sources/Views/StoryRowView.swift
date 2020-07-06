//
//  StoryRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/01/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

// TODO: fix separator when row is selected

import AppKit

class StoryRowView: NSTableRowView {
    // MARK: Properties

    override var isNextRowSelected: Bool {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    // MARK: Methods

    override func drawSeparator(in _: NSRect) {
        guard
            let cgContext = NSGraphicsContext.current?.cgContext,
            let cellView = view(atColumn: 0) as? StoryCellView
        else {
            return
        }
        
        cgContext.saveGState()

        let margin: CGFloat = cellView.containerStackView.edgeInsets.right,
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
            )

        cgContext.setFillColor(NSColor.gridColor.cgColor)

        if isSelected {
            cgContext.fill(bottomRect)
        }

        if !isNextRowSelected {
            cgContext.fill(topRect)
        }

        cgContext.restoreGState()
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let storyRow = NSUserInterfaceItemIdentifier("StoryRow")
}
