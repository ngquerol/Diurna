//
//  NSTextView+AttributedStringValue.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 14/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

extension NSAttributedString {

    static let empty = NSAttributedString()
}

extension NSTextView {

    var attributedStringValue: NSAttributedString {
        get {
            return attributedString()
        }

        set {
            textStorage?.setAttributedString(newValue)
        }
    }
}
