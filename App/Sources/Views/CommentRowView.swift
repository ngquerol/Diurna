//
//  CommentRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/02/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class CommentRowView: NSTableRowView {
    // MARK: Properties

    private static let indentGuideColors: [CGColor] = {
        [
            NSColor.systemBlue,
            NSColor.systemGreen,
            NSColor.systemOrange,
            NSColor.systemRed,
            NSColor.systemBrown,
        ].map {
            $0.withAlphaComponent(0.6).cgColor
        }
    }()

    private let indentGuideWidth: CGFloat = 3

    // MARK: Methods

    private static func indentGuideColor(for level: Int) -> CGColor {
        guard level > 0 else { return .clear }
        let colorIndex = (level - 1) % indentGuideColors.count
        return indentGuideColors[colorIndex]
    }

    override func drawSeparator(in _: NSRect) {
        guard
            let outlineView = superview as? CommentsOutlineView,
            let cellView = view(atColumn: 0) as? CommentCellView,
            let cgContext = NSGraphicsContext.current?.cgContext
        else {
            return
        }

        let rowIndex = outlineView.row(for: cellView)

        guard rowIndex > 0 else { return }

        let rowLevel = outlineView.level(forRow: rowIndex),
            indentWidth = CGFloat(rowLevel) * outlineView.indentationPerLevel,
            indentGuideWidth = (rowLevel == 0 ? 0 : self.indentGuideWidth),
            separatorHeight: CGFloat = 1,
            margin = cellView.trailingSpacingConstraint.constant

        cgContext.saveGState()

        cgContext.setFillColor(outlineView.gridColor.cgColor)
        cgContext.fill(
            CGRect(
                x: indentWidth - indentGuideWidth,
                y: 0,
                width: frame.width + indentGuideWidth - (margin + indentWidth),
                height: separatorHeight
            )
        )

        cgContext.restoreGState()
    }

    override func drawBackground(in dirtyRect: NSRect) {
        super.drawBackground(in: dirtyRect)

        guard
            let outlineView = superview as? CommentsOutlineView,
            let cellView = view(atColumn: 0) as? CommentCellView,
            let cgContext = NSGraphicsContext.current?.cgContext
        else {
            return
        }

        let rowIndex = outlineView.row(for: cellView),
            rowLevel = outlineView.level(forRow: rowIndex)

        guard rowLevel > 0 else { return }

        let indentWidth = CGFloat(rowLevel) * outlineView.indentationPerLevel,
            indentRect = CGRect(
                x: indentWidth - indentGuideWidth,
                y: cellView.frame.origin.y,
                width: indentGuideWidth,
                height: cellView.frame.height
            )

        cgContext.saveGState()

        cgContext.addPath(
            CGPath(
                roundedRect: indentRect,
                cornerWidth: indentGuideWidth,
                cornerHeight: indentGuideWidth,
                transform: nil
            )
        )
        cgContext.setFillColor(CommentRowView.indentGuideColor(for: rowLevel))
        cgContext.fillPath()

        cgContext.restoreGState()
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let commentRow = NSUserInterfaceItemIdentifier("CommentRow")
}
