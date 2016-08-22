//
//  ClickableTextField.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 23/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable
class ClickableTextField: NSTextField {

    override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }
}
