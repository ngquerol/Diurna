//
//  CommentsOutlineView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 25/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentsOutlineView: NSOutlineView {

    // MARK: Methods

    func flashRow(at rowIndex: Int, with color: NSColor) {
        guard let rowView = rowView(atRow: rowIndex, makeIfNecessary: false) else {
            return
        }

        let currentBackgroundColor = rowView.backgroundColor

        rowView.layer?.masksToBounds = true
        rowView.layer?.cornerRadius = 5
        rowView.layer?.borderWidth = 10
        rowView.layer?.borderColor = .clear
        rowView.layer?.bounds = rowView.bounds.insetBy(dx: 5, dy: 5)
        rowView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        rowView.layer?.position = CGPoint(x: rowView.frame.midX, y: rowView.frame.midY)

        NSAnimationContext.runAnimationGroup({ _ in
            scrollRowToVisible(rowIndex)
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                rowView.animator().backgroundColor = color
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ _ in
                    rowView.animator().backgroundColor = currentBackgroundColor
                })
            })
        })
    }

    override func frameOfOutlineCell(atRow _: Int) -> NSRect {
        return .zero // don't show the disclosure triangle
    }

    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        var frame = super.frameOfCell(atColumn: column, row: row)

        frame.origin.x -= indentationPerLevel
        frame.size.width += indentationPerLevel

        return frame
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil),
            rowAtPoint = row(at: point)

        guard
            rowAtPoint != -1,
            let comment = item(atRow: rowAtPoint) as? Comment
        else {
            return nil
        }

        let menu = NSMenu(title: "Comment Context Menu"),
            menuItem = menu.addItem(withTitle: "Open in browser", action: .openCommentInBrowser, keyEquivalent: "")
        menuItem.representedObject = comment

        return menu
    }

    @objc func openCommentInBrowser(_ sender: NSMenuItem) {
        guard let comment = sender.representedObject as? Comment else { return }

        let commentURL = HackerNewsWebpage.item(comment.id).path

        do {
            try NSWorkspace.shared.open(commentURL, options: .withoutActivation, configuration: [:])
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
    }
}

// MARK: - Selectors

private extension Selector {
    static let openCommentInBrowser = #selector(CommentsOutlineView.openCommentInBrowser(_:))
}
