//
//  DisclosureButtonView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 06/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class DisclosureButtonView: NSButton {
    // MARK: Properties

    @IBInspectable var collapsedImage: NSImage?

    @IBInspectable var collapsedTooltip: String?

    @IBInspectable var expandedImage: NSImage?

    @IBInspectable var expandedTooltip: String?

    @IBInspectable var isExpanded: Bool = false {
        didSet {
            toolTip = isExpanded ? expandedTooltip : collapsedTooltip
        }
    }

    // MARK: Methods

    override func resetCursorRects() {
        guard isEnabled else { return }

        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        isExpanded.toggle()

        animateDisclosure()

        return super.sendAction(action, to: target)
    }

    private func animateDisclosure() {
        let transformRotate = CABasicAnimation(keyPath: "transform.rotation")
        transformRotate.fromValue = layer?.affineTransform
        transformRotate.duration = 0.25
        transformRotate.timingFunction = CAMediaTimingFunction(name: .easeIn)

        layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer?.position = CGPoint(x: frame.midX, y: frame.midY)
        layer?.setAffineTransform(layer?.affineTransform().rotated(by: .pi) ?? .identity)

        layer?.add(transformRotate, forKey: "transform")
    }
}
