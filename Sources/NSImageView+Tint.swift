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
        guard let tinted = copy() as? NSImage else {
            return self
        }

        let imageRect = NSRect(origin: .zero, size: size)

        tinted.lockFocus()

        color.setFill()
        imageRect.fill(using: .sourceAtop)

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
