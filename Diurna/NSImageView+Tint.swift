//
//  NSImageView+Tint.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 19/08/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

extension NSImage {
    func tint(with color: NSColor) -> NSImage {
        let tinted = self.copy() as! NSImage

        tinted.lockFocus()
        color.setFill()
        NSRectFillUsingOperation(NSRect(origin: NSZeroPoint, size: self.size), .sourceAtop)
        tinted.unlockFocus()

        return tinted
    }
}

extension NSImageView {
    func tintImage(with color: NSColor) {
        guard let image = image else { return }

        self.image = image.tint(with: color)
    }
}
