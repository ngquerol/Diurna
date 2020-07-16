//
//  CommentsOutlineView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 25/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class CommentsOutlineView: NSOutlineView {
    // MARK: Properties

    private let outlineCellWidth: CGFloat = 16

    // MARK: Methods

    // Remove disclosure triangle ("outline cell")

    override func frameOfOutlineCell(atRow _: Int) -> NSRect {
        .zero
    }

    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        let frame = super.frameOfCell(atColumn: column, row: row)

        return NSRect(
            x: frame.origin.x - outlineCellWidth,
            y: frame.origin.y,
            width: frame.width + outlineCellWidth,
            height: frame.height
        )
    }

    override func drawGrid(inClipRect clipRect: NSRect) {}

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let rowAtPoint = row(at: point)

        guard
            rowAtPoint != -1,
            let comment = item(atRow: rowAtPoint) as? Comment
        else {
            return nil
        }

        let menu = NSMenu(title: "Comment Context Menu")
        let menuItem =
            menu
            .addItem(withTitle: "Open in browser", action: .openCommentInBrowser, keyEquivalent: "")
        menuItem.representedObject = comment

        return menu
    }

    @objc func openCommentInBrowser(_ sender: NSMenuItem) {
        guard let comment = sender.representedObject as? Comment else { return }

        let commentURL = HNWebpage.item(comment.id).path

        do {
            try NSWorkspace.shared.open(commentURL, options: .withoutActivation, configuration: [:])
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
    }
}

// MARK: - Selectors

extension Selector {
    fileprivate static let openCommentInBrowser = #selector(
        CommentsOutlineView
            .openCommentInBrowser(_:))
}
