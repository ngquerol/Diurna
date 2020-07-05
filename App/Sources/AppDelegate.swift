//
//  AppDelegate.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

import Firebase

@NSApplicationMain
class AppDelegate: NSObject {
    // MARK: Properties

    lazy var aboutWindow: NSWindowController = AboutWindowController(windowNibName: .aboutWindow)

    // MARK: Methods

    @IBAction func toggleSidebar(_ sender: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let mainSplitViewController = window.contentViewController as? MainSplitViewController
        else {
            return
        }

        mainSplitViewController.toggleSidebar(sender)
    }

    @IBAction func toggleStoryDetails(_: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let mainSplitViewController = window.contentViewController as? MainSplitViewController
        else {
            return
        }

        mainSplitViewController.storyDetailsSplitViewItem.animator().isCollapsed.toggle()
    }

    @IBAction func searchStories(_: NSMenuItem) {
        guard
            let window = NSApp.windows.first,
            let mainSplitViewController = window.contentViewController as? MainSplitViewController,
            let storiesViewController = mainSplitViewController.storiesSplitViewItem?.viewController
            as? StoriesViewController
        else {
            return
        }

        window.makeFirstResponder(storiesViewController.searchField)
    }
}

// MARK: - NSApplicationDelegate

extension AppDelegate: NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
    }
}
