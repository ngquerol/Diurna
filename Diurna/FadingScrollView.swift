//
//  FadingScrollView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class FadingScrollView: NSScrollView {

    let fadePercentage: Float = 0.05

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
            NSNumber(value: fadePercentage),
//            NSNumber(value: 1 - fadePercentage),
            1
        ]

        maskLayer.addSublayer(gradientLayer)
        layer?.mask = maskLayer
    }
}
