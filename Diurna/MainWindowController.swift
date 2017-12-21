//
//  MainWindowController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    // MARK: Window Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else { return }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = Themes.current.backgroundColor

        window.standardWindowButton(.closeButton)?.frame.origin.y -= 5
        window.standardWindowButton(.zoomButton)?.frame.origin.y -= 5
        window.standardWindowButton(.miniaturizeButton)?.frame.origin.y -= 5
    }
}

// MARK: - NSWindowDelegate
extension MainWindowController: NSWindowDelegate {
    func windowWillEnterFullScreen(_: Notification) {
        NotificationCenter.default.post(name: .enterFullScreenNotification, object: self)
    }

    func windowWillExitFullScreen(_: Notification) {
        NotificationCenter.default.post(name: .exitFullScreenNotification, object: self)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let enterFullScreenNotification = Notification.Name("EnterFullScreenNotification")
    static let exitFullScreenNotification = Notification.Name("ExitFullScreenNotification")
}
