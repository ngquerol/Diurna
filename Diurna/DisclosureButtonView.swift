//
//  DisclosureButtonView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 06/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable class DisclosureButtonView: NSButton {

    @IBInspectable var collapseImage: NSImage = #imageLiteral(resourceName: "CollapseIcon")
    @IBInspectable var expandImage: NSImage = #imageLiteral(resourceName: "ExpandIcon")
    @IBInspectable var isCollapsed: Bool = true {
        willSet {
            layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer?.position = CGPoint(
                x: frame.origin.x + frame.width / 2,
                y: frame.origin.y + frame.height / 2
            )

            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().allowsImplicitAnimation = true

            if newValue {
                layer?.add(expandAnimation, forKey: nil)
                image = collapseImage
            } else {
                layer?.add(collapseAnimation, forKey: nil)
                image = expandImage
            }

            NSAnimationContext.endGrouping()
        }
    }

    private lazy var expandAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")

        animation.fromValue = CGFloat.pi
        animation.toValue = 2 * CGFloat.pi
        animation.duration = 0.2

        return animation
    }()

    private lazy var collapseAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")

        animation.fromValue = CGFloat.pi
        animation.toValue = 0
        animation.duration = 0.2

        return animation
    }()


    override func awakeFromNib() {
        super.awakeFromNib()
        commonSetup()
    }

    private func commonSetup() {
        image = isCollapsed ? expandImage : collapseImage
    }
}
