//
//  AppDelegate.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    weak var window: NSWindow?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window = NSApplication.sharedApplication().windows.first
        window?.titleVisibility = .Hidden
        window?.titlebarAppearsTransparent = true
        window?.styleMask |= NSFullSizeContentViewWindowMask
        window?.movableByWindowBackground = true
    }

    func applicationWillTerminate(aNotification: NSNotification) { }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
