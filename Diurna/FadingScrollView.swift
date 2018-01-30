//
//  FadingScrollView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable class FadingScrollView: NSScrollView {

    @IBInspectable var topFadePercentage: CGFloat = 0

    @IBInspectable var bottomFadePercentage: CGFloat = 0

    override func layout() {
        super.layout()

        let maskLayer = CALayer()
        maskLayer.frame = bounds

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSRect(
            x: bounds.origin.x,
            y: 0,
            width: bounds.size.width,
            height: bounds.size.height
        )

        let transparent = NSColor.clear.cgColor,
            opaque = NSColor.controlDarkShadowColor.cgColor

        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [
            0,
            (topFadePercentage / 100) as NSNumber,
            (1 - (bottomFadePercentage / 100)) as NSNumber,
            1,
        ]

        maskLayer.addSublayer(gradientLayer)
        layer?.mask = maskLayer
    }
}
