//
//  ThemeableButton.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class ThemeableButton: NSButton {

    @IBInspectable var widthPadding: CGFloat {
        get {
            return themeableCell?.widthPadding ?? 10
        }

        set {
            themeableCell?.widthPadding = newValue
        }
    }

    @IBInspectable var heightPadding: CGFloat {
        get {
            return themeableCell?.heightPadding ?? 0
        }

        set {
            themeableCell?.heightPadding = newValue
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return themeableCell?.borderWidth ?? 1
        }

        set {
            themeableCell?.borderWidth = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return themeableCell?.cornerRadius ?? 5
        }

        set {
            themeableCell?.cornerRadius = newValue
        }
    }

    @IBInspectable var buttonColor: NSColor {
        get {
            return themeableCell?.buttonColor ?? Themes.current.secondaryTextColor
        }

        set {
            themeableCell?.buttonColor = newValue
        }
    }

    @IBInspectable var textColor: NSColor {
        get {
            return themeableCell?.textColor ?? Themes.current.normalTextColor
        }

        set {
            themeableCell?.textColor = newValue
        }
    }

    @IBInspectable var borderColor: NSColor {
        get {
            return themeableCell?.borderColor ?? NSColor.lightGray.shadow(withLevel: 0.4)!
        }

        set {
            themeableCell?.borderColor = newValue
        }
    }

    var cursor: NSCursor?

    private var themeableCell: ThemeableCell? {
        return cell as? ThemeableCell
    }

    override func resetCursorRects() {
        if let cursor = cursor {
            addCursorRect(bounds, cursor: cursor)
        } else {
            super.resetCursorRects()
        }
    }
}

class ThemeableCell: NSButtonCell {

    var widthPadding: CGFloat = 10

    var heightPadding: CGFloat = 0

    var borderWidth: CGFloat = 1

    var cornerRadius: CGFloat = 5

    var borderColor: NSColor = NSColor.lightGray.shadow(withLevel: 0.4)!

    var buttonColor: NSColor = .lightGray {
        didSet {
            backgroundColor = buttonColor
        }
    }

    var textColor: NSColor = Themes.current.normalTextColor {
        didSet {
            changeButtonTitleColor()
        }
    }

    var highlightedTextColor: NSColor {
        return textColor.highlight(withLevel: 0.2)!
    }

    var highlightedButtonColor: NSColor {
        return buttonColor.shadow(withLevel: 0.2)!
    }

    private var disabledButtonColor: NSColor {
        return buttonColor.withAlphaComponent(0.5)
    }

    override var bezelStyle: NSButton.BezelStyle {
        get { return .roundRect }
        set {}
    }

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = buttonColor
            } else {
                backgroundColor = disabledButtonColor
            }
        }
    }

    override var cellSize: NSSize {
        let buttonSize = super.cellSize

        return NSSize(width: buttonSize.width + 2.0 * widthPadding,
                      height: buttonSize.height + 2.0 * heightPadding)
    }

    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {
        backgroundColor = flag ? highlightedButtonColor : buttonColor

        changeButtonTitleColor()

        super.highlight(flag, withFrame: cellFrame, in: controlView)
    }

    override func drawBezel(withFrame frame: NSRect, in _: NSView) {
        guard let graphicsContext = NSGraphicsContext.current else {
            return
        }

        graphicsContext.shouldAntialias = true
        graphicsContext.saveGraphicsState()

        let path = NSBezierPath(roundedRect: frame, xRadius: cornerRadius, yRadius: cornerRadius)
        path.lineWidth = borderWidth
        path.setClip()

        if isHighlighted {
            highlightedButtonColor.setFill()
        } else {
            buttonColor.setFill()
        }

        path.fill()

        if isBordered {
            borderColor.setStroke()
            path.stroke()
        }

        graphicsContext.restoreGraphicsState()
    }

    override func drawTitle(_ title: NSAttributedString, withFrame _: NSRect, in controlView: NSView) -> NSRect {
        let buttonFrame = controlView.bounds
        var titleFrame = title.boundingRect(with: buttonFrame.size, options: [])

        let deltaX = buttonFrame.midX - titleFrame.midX,
            deltaY = buttonFrame.midY - titleFrame.midY

        titleFrame.origin.x = ceil(titleFrame.origin.x + deltaX)
        titleFrame.origin.y = ceil(titleFrame.origin.y + deltaY)

        title.draw(in: titleFrame)

        return titleFrame
    }

    private func changeButtonTitleColor() {
        let font = attributedTitle.attribute(
            NSAttributedStringKey.font,
            at: 0,
            effectiveRange: nil
        ) as? NSFont ?? .systemFont(ofSize: NSFont.systemFontSize(for: self.controlSize))

        attributedTitle = NSAttributedString(string: title, attributes: [
            NSAttributedStringKey.foregroundColor: isHighlighted ? highlightedTextColor : textColor,
            NSAttributedStringKey.font: font
        ])
    }
}
