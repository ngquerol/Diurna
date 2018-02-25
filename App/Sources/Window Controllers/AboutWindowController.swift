//
//  AboutWindowController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 05/11/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class AboutWindowController: NSWindowController {
    // MARK: Window Lifecycle

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
    }
}

// MARK: - NSNib.Name

extension NSNib.Name {
    static let aboutWindow = "AboutWindow"
}
