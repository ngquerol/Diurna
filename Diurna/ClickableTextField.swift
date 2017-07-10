//
//  ClickableTextField.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 11/06/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class ClickableTextField: NSTextField {

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }

        sendAction(action, to: target)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
