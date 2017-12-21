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

    // MARK: Outlets
    @IBOutlet weak var themesMenu: NSMenuItem!

    // MARK: Properties
    lazy var aboutWindow: NSWindowController = AboutWindowController(windowNibName: .aboutWindow)

    // MARK: Methods

    // TODO: Use a notification instead of accessing the SplitViewController directly
    @IBAction func toggleSidebar(_ sender: NSMenuItem) {
        guard let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController else { return }

        splitViewController.toggleSidebar(sender)
    }

    @IBAction func toggleComments(_: NSMenuItem) {
        guard let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController else { return }

        let commentsView = splitViewController.splitViewItems[2]

        commentsView.animator().isCollapsed = !commentsView.isCollapsed
    }

    @IBAction func userDidChangeTheme(_ sender: NSMenuItem) {
        print(sender.title)
    }
}

// MARK: - NSApplicationDelegate
extension AppDelegate: NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
