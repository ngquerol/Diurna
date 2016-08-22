//
//  BadgeView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 04/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class BadgeView: NSView {

    @IBInspectable var text: String = "" {
        didSet {
            refreshAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var fontName: String = NSFont.systemFont(ofSize: NSFont.systemFontSize(), weight: NSFontWeightSemibold).fontName {
        didSet {
            refreshAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var fontSize: CGFloat = NSFont.systemFontSize() {
        didSet {
            refreshAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var foregroundColor: NSColor = .black {
        didSet {
            refreshAttributedString()
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var horizontalPadding: CGFloat = 0.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    @IBInspectable var borderWidth: CGFloat = 0.0
    @IBInspectable var borderColor: NSColor = .black
    @IBInspectable var cornerRadius: CGFloat = 0.0
    @IBInspectable var backgroundColor: NSColor = .white

    private var defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize(), weight: NSFontWeightMedium)

    private var textParagraphStyle: NSParagraphStyle {
        get {
            let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle

            paragraphStyle.alignment = NSTextAlignment.center

            return paragraphStyle
        }
    }

    private var textAttributedString: NSAttributedString = NSAttributedString()

    override var intrinsicContentSize: NSSize {
        get {
            let roundedWidth = ceil(textAttributedString.size().width)
            return NSSize(width: roundedWidth + horizontalPadding * 2, height: NSViewNoIntrinsicMetric)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: dirtyRect, xRadius: cornerRadius, yRadius: cornerRadius)

        backgroundColor.setFill()
        path.fill()

        if borderWidth >= 1.0 {
            let borderRect = dirtyRect.insetBy(dx: borderWidth, dy: borderWidth),
                borderPath = NSBezierPath(roundedRect: borderRect, xRadius: cornerRadius, yRadius: cornerRadius)
            borderColor.setStroke()
            borderPath.stroke()
        }

        foregroundColor.setStroke()

        let textRectHeight = ceil(textAttributedString.size().height),
        textRectOrigin = dirtyRect.origin.y + (dirtyRect.height / 2 - textRectHeight / 2),
        textRect = NSRect(x: dirtyRect.origin.x,
                          y: textRectOrigin,
                          width: dirtyRect.size.width,
                          height: textRectHeight)
        
        textAttributedString.draw(in: textRect)
    }

    private func refreshAttributedString() {
        textAttributedString = NSAttributedString(
            string: text,
            attributes: [
                NSFontAttributeName: NSFont(name: fontName, size: fontSize) ?? defaultFont,
                NSParagraphStyleAttributeName: textParagraphStyle,
                NSForegroundColorAttributeName: foregroundColor
            ]
        )
    }
}
