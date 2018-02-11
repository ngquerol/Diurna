//
//  SelfSizingTextView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 08/01/2018.
//  Copyright © 2018 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class SelfSizingTextView: NSTextView {

    // MARK: Properties

    override var intrinsicContentSize: NSSize {
        guard
            let container = textContainer,
            let manager = layoutManager
        else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }

        let availableWidth = frame.width - textContainerInset.width

        container.size = NSSize(width: availableWidth, height: .greatestFiniteMagnitude)
        manager.ensureLayout(for: container)

        let size = manager.usedRect(for: container)

        return NSSize(
            width: size.width + textContainerInset.width,
            height: size.height + textContainerInset.height
        )
    }

    override var textContainerOrigin: NSPoint {
        var origin = super.textContainerOrigin

        origin.x -= textContainerInset.width / 2.0
        origin.y -= textContainerInset.height / 2.0

        return origin
    }

    override var string: String {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var attributedStringValue: NSAttributedString {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: Methods

    override func layout() {
        super.layout()

        if frame.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override func didChangeText() {
        super.didChangeText()

        invalidateIntrinsicContentSize()
    }
}
