//
//  SelfSizingTextView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 08/01/2018.
//  Copyright © 2018 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class SelfSizingTextView: NSTextView {
    // MARK: Properties

    override var intrinsicContentSize: NSSize {
        guard
            let container = textContainer,
            let manager = layoutManager
        else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }

        guard attributedStringValue.length > 0 else {
            return .zero
        }

        let availableWidth = frame.width - textContainerInset.width
        container.size = NSSize(width: availableWidth, height: .greatestFiniteMagnitude)

        manager.ensureLayout(for: container)

        let boundingRect = manager.usedRect(for: container)

        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: boundingRect.height + textContainerInset.height
        )
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

        invalidateIntrinsicContentSize()
    }

    override func didChangeText() {
        super.didChangeText()

        invalidateIntrinsicContentSize()
    }
}
