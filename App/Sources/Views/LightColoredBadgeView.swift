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
        return NSSize(
            width: ceil(titleSize.width) + horizontalPadding * 2,
            height: titleSize.height
        )
    }

    private let textParagraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = NSTextAlignment.center
        return paragraphStyle
    }()

    private var titleAttributedString: NSAttributedString = .empty

    // MARK: Methods

    override func draw(_ dirtyRect: NSRect) {
        guard let cgContext = NSGraphicsContext.current?.cgContext else { return }

        cgContext.saveGState()

        let borderPath = CGPath(
            roundedRect: dirtyRect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        cgContext.setLineWidth(borderWidth)

        cgContext.addPath(borderPath)
        cgContext.clip()

        cgContext.setFillColor(color.withAlphaComponent(0.25).cgColor)
        cgContext.fill(dirtyRect)

        cgContext.addPath(borderPath)
        cgContext.setStrokeColor(color.withAlphaComponent(0.75).cgColor)
        cgContext.strokePath()

        let textRectHeight = ceil(titleAttributedString.size().height),
            textRectOrigin = dirtyRect.origin.y + (dirtyRect.midY - textRectHeight / 2),
            textRect = CGRect(
                x: dirtyRect.origin.x,
                y: textRectOrigin,
                width: dirtyRect.size.width,
                height: textRectHeight
            )

        titleAttributedString.draw(in: textRect)

        cgContext.restoreGState()
    }

    private func updateTitleAttributedString() {
        titleAttributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: NSFont.Weight.semibold),
                .paragraphStyle: textParagraphStyle,
                .foregroundColor: color,
            ]
        )
    }
}
