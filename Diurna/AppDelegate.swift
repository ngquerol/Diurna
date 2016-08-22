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
    lazy var aboutWindow: NSWindowController = AboutWindowController(windowNibName: "AboutWindow")

    // MARK: Methods
    @IBAction func showAboutWindow(_ sender: NSMenuItem) {
        aboutWindow.showWindow(sender)
    }

    // TODO: Use a notification instead of accessing the SplitViewController directly
    @IBAction func toggleSidebar(_ sender: NSMenuItem) {
        guard let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController else { return }
        
        splitViewController.toggleSidebar(sender)
    }

    @IBAction func toggleComments(_ sender: NSMenuItem) {
        guard let window = NSApp.windows.first,
            let splitViewController = window.contentViewController as? NSSplitViewController else { return }

        let commentsView = splitViewController.splitViewItems[2]

        commentsView.animator().isCollapsed = !commentsView.isCollapsed
    }
}

// MARK: - NSApplicationDelegate
extension AppDelegate: NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
