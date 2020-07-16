//
//  StoriesTableView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 22/07/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class StoriesTableView: NSTableView {
    // MARK: Methods

    override func drawGrid(inClipRect clipRect: NSRect) {}

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let rowAtPoint = row(at: point)

        guard rowAtPoint != -1 else { return nil }

        let menu = NSMenu(title: "Story Context Menu")
        let item =
            menu
            .addItem(withTitle: "Open in browser", action: .openStoryInBrowser, keyEquivalent: "")

        guard
            let cellView = view(
                atColumn: 0,
                row: rowAtPoint,
                makeIfNecessary: false
            ) as? StoryCellView,
            let story = cellView.objectValue as? Story
        else {
            return nil
        }

        item.representedObject = story

        return menu
    }

    @objc func openStoryInBrowser(_ sender: NSMenuItem) {
        guard let story = sender.representedObject as? Story else { return }

        let storyURL = HNWebpage.item(story.id).path

        do {
            try NSWorkspace.shared.open(storyURL, options: .withoutActivation, configuration: [:])
        } catch let error as NSError {
            NSAlert(error: error).runModal()
        }
    }
}

// MARK: - Selectors

extension Selector {
    fileprivate static let openStoryInBrowser = #selector(StoriesTableView.openStoryInBrowser(_:))
}
