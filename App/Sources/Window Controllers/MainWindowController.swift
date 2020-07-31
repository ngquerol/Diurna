//
//  MainWindowController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class MainWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.isMovableByWindowBackground = true

        // FIXME: moves when resizing the window
        [
            window?.standardWindowButton(.closeButton),
            window?.standardWindowButton(.zoomButton),
            window?.standardWindowButton(.miniaturizeButton),
        ].forEach {
            $0?.frame.origin.x += 7.5
            $0?.frame.origin.y -= 5
        }
    }
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    func windowWillEnterFullScreen(_: Notification) {
        guard
            let mainSplitView = contentViewController as? MainSplitViewController,
            let sidebarSplitViewItem = mainSplitView.sidebarSplitViewItem,
            let categoriesViewController =
                sidebarSplitViewItem
                .viewController as? SidebarViewController
        else {
            return
        }

        // TODO: do not hardcode constraint value if possible
        categoriesViewController.topSpacingConstraint.animator().constant = 0.0
    }

    func windowWillExitFullScreen(_: Notification) {
        guard
            let mainSplitView = contentViewController as? MainSplitViewController,
            let sidebarSplitViewItem = mainSplitView.sidebarSplitViewItem,
            let categoriesViewController =
                sidebarSplitViewItem
                .viewController as? SidebarViewController
        else {
            return
        }

        // TODO: do not hardcode constraint value if possible
        categoriesViewController.topSpacingConstraint.animator().constant = 30.0
    }
}
