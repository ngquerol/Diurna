//
//  AppDelegate.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject {

    // MARK: Properties

    lazy var aboutWindow: NSWindowController = AboutWindowController(windowNibName: .aboutWindow)

    // MARK: Methods

    @IBAction func toggleSidebar(_ sender: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController
        else {
            return
        }

        splitViewController.toggleSidebar(sender)
    }

    @IBAction func searchStories(_: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController,
            let storiesViewController = splitViewController.splitViewItems[1].viewController as? StoriesViewController
        else {
            return
        }

        window.makeFirstResponder(storiesViewController.storiesSearchField)
    }

    @IBAction func toggleComments(_: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController
        else {
            return
        }

        let commentsView = splitViewController.splitViewItems[2]

        commentsView.animator().isCollapsed = !commentsView.isCollapsed
    }
}

// MARK: - NSApplicationDelegate

extension AppDelegate: NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
