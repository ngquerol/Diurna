//
//  ClearRoundRectButtonCell.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/03/2017.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

@IBDesignable class ClearRoundRectButtonCell: NSButtonCell {
    // MARK: Inspectables

    @IBInspectable var widthPadding: CGFloat = 0

    @IBInspectable var heightPadding: CGFloat = 0

    @IBInspectable var borderWidth: CGFloat = 1

    @IBInspectable var cornerRadius: CGFloat = 5

    // MARK: Colors

    private let titleColor: NSColor = .controlTextColor

    private let borderColor: NSColor = .gridColor

    private let selectionForegroundColor: NSColor = .white

    private var selectionBackgroundColor: NSColor {
        if #available(macOS 10.14, *) {
            return .controlAccentColor
        } else {
            return .systemBlue
        }
    }

    private var fillStrokeColors: (NSColor, NSColor) {
        guard isEnabled else { return (.clear, .disabledControlTextColor) }

        switch (isSelected, isHighlighted) {
        case (true, false):
            return (.clear, selectionForegroundColor)
        case (true, true):
            return (selectionBackgroundColor, selectionForegroundColor)
        case (false, true):
            return (selectionBackgroundColor, borderColor)
        default:
            return (.clear, borderColor)
        }
    }

    // MARK: NSButtonCell properties

    override var bezelStyle: NSButton.BezelStyle {
        get { return .roundRect }
        set {}
    }

    override var backgroundColor: NSColor? {
        get { return .clear }
        set {}
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            changeTitleColor(to: isSelected ? selectionForegroundColor : titleColor)
        }
    }

    override var isBordered: Bool {
        get { return true }
        set {}
    }

    override var cellSize: NSSize {
        let buttonSize = super.cellSize

        return NSSize(
            width: buttonSize.width + 2.0 * widthPadding,
            height: buttonSize.height + 2.0 * heightPadding
        )
    }

    // MARK: State

    private var isSelected: Bool { return backgroundStyle == .emphasized }

    // MARK: Methods

    override func highlight(_ flag: Bool, withFrame frame: NSRect, in controlView: NSView) {
        super.highlight(flag, withFrame: frame, in: controlView)

        changeTitleColor(to: (isHighlighted || isSelected) ? selectionForegroundColor : titleColor)
    }

    override func drawBezel(withFrame frame: NSRect, in _: NSView) {
        guard let cgContext = NSGraphicsContext.current?.cgContext else { return }

        cgContext.saveGState()

        let borderPath = CGPath(
            roundedRect: frame,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        cgContext.setLineWidth(borderWidth)

        cgContext.addPath(borderPath)
        cgContext.clip()

        cgContext.setFillColor(fillStrokeColors.0.cgColor)
        cgContext.fill(frame)

        cgContext.addPath(borderPath)
        cgContext.setStrokeColor(fillStrokeColors.1.cgColor)
        cgContext.strokePath()

        cgContext.restoreGState()
    }

    private func changeTitleColor(to color: NSColor) {
        let newTitle = NSMutableAttributedString(attributedString: attributedTitle),
            range = NSRange(location: 0, length: newTitle.length)

        newTitle.addAttribute(.foregroundColor, value: color, range: range)

        attributedTitle = newTitle
    }
}
