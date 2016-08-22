//
//  MainWindowController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else { return }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .white

        window.standardWindowButton(NSWindowButton.closeButton)?.frame.origin.y -= 4
        window.standardWindowButton(NSWindowButton.zoomButton)?.frame.origin.y -= 4
        window.standardWindowButton(NSWindowButton.miniaturizeButton)?.frame.origin.y -= 4
    }
}
