//
//  LightColoredBadgeView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 04/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class LightColoredBadgeView: NSView {

    // MARK: Outlets
    @IBInspectable var text: String = "Badge" {
        didSet {
            updateTitleAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var fontSize: CGFloat = NSFont.systemFontSize {
        didSet {
            updateTitleAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var color: NSColor = .lightGray {
        didSet {
            updateTitleAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var horizontalPadding: CGFloat = 0.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0.0
    @IBInspectable var cornerRadius: CGFloat = 0.0

    // MARK: Properties
    override var intrinsicContentSize: NSSize {
        let titleSize = titleAttributedString.size()
        return NSSize(width: ceil(titleSize.width) + horizontalPadding * 2, height: titleSize.height)
    }

    private var defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: NSFont.Weight.medium)

    private var textParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle

        paragraphStyle.alignment = NSTextAlignment.center

        return paragraphStyle
    }

    private var titleAttributedString: NSAttributedString = NSAttributedString()

    private var isPressed = false {
        didSet {
            updateTitleAttributedString()
            setNeedsDisplay(bounds)
        }
    }

    // MARK: Methods
    override func mouseDown(with _: NSEvent) {
        isPressed = true
    }

    override func mouseUp(with _: NSEvent) {
        isPressed = false
    }

    override func draw(_ dirtyRect: NSRect) {
        let drawingRect = dirtyRect.insetBy(dx: borderWidth, dy: borderWidth),
            borderPath = NSBezierPath(roundedRect: drawingRect, xRadius: cornerRadius, yRadius: cornerRadius),
            fillColor = color.blended(withFraction: isPressed ? 0.5 : 0.95, of: .white)!,
            borderColor = color.blended(withFraction: isPressed ? 0.25 : 0.65, of: .white)!

        fillColor.setFill()
        drawingRect.fill()

        borderColor.setStroke()
        borderPath.lineWidth = borderWidth
        borderPath.stroke()

        let textRectHeight = ceil(titleAttributedString.size().height),
            textRectOrigin = dirtyRect.origin.y + (dirtyRect.midY - textRectHeight / 2),
            textRect = NSRect(x: dirtyRect.origin.x,
                              y: textRectOrigin,
                              width: dirtyRect.size.width,
                              height: textRectHeight)

        titleAttributedString.draw(in: textRect)
    }

    private func updateTitleAttributedString() {
        titleAttributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.semibold),
                .paragraphStyle: textParagraphStyle,
                .foregroundColor: isPressed ? color.blended(withFraction: 0.95, of: .white)! : color,
            ]
        )
    }
}
