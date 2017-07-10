//
//  DisclosureButtonView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 06/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable class DisclosureButtonView: NSButton {

    // MARK: Properties
    @IBInspectable var collapseImage: NSImage = #imageLiteral(resourceName: "CollapseIcon")

    @IBInspectable var expandImage: NSImage = #imageLiteral(resourceName: "ExpandIcon")

    @IBInspectable var isExpanded: Bool = true

    override var title: String {
        get {
            return isExpanded ? "Collapse this comment" : "Expand this comment"
        }

        set { }
    }

    // MARK: View Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        image = isExpanded ? collapseImage : expandImage
    }

    // MARK: Methods
    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        isExpanded = !isExpanded

        animateDisclosure()

        return super.sendAction(action, to: target)
    }

    private func animateDisclosure() {
        let currentAngle = layer?.value(forKeyPath: "transform.rotation.z") as! Double,
            rotationAngle = isExpanded ? -Double.pi : Double.pi,
            destinationAngle = currentAngle + rotationAngle

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = NSNumber(value: currentAngle)
        animation.toValue = NSNumber(value: destinationAngle)
        animation.duration = 0.25
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

        layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer?.position = CGPoint(x: frame.origin.x + frame.midX, y: frame.origin.y + frame.midY)
        layer?.add(animation, forKey: nil)
        layer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(destinationAngle)))
    }
}
