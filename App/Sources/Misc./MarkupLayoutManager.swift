//
//  MarkupLayoutManager.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class MarkupLayoutManager: NSLayoutManager {
    // MARK: Properties

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        drawCodeBlocks(forGlyphRange: glyphsToShow, at: origin)

        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }

    // MARK: Methods

    private func drawCodeBlocks(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard
            let textStorage = textStorage,
            let cgContext = NSGraphicsContext.current?.cgContext
        else {
            return
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage
            .enumerateAttribute(.codeBlock, in: characterRange, options: []) { value, range, _ in
                guard let fillColor = value as? NSColor else { return }

                let blockGlyphRange = glyphRange(
                    forCharacterRange: range,
                    actualCharacterRange: nil
                )
                var blockRect: CGRect?

                enumerateLineFragments(forGlyphRange: blockGlyphRange) { rect, _, _, _, _ in
                    let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                    blockRect = blockRect == nil ? lineRect : blockRect?.union(lineRect)
                }

                if let blockRect = blockRect {
                    let widthAdjustment: CGFloat = 5
                    let effectiveBlockRect = NSRect(
                        x: blockRect.origin.x + widthAdjustment / 2,
                        y: blockRect.origin.y,
                        width: blockRect.width - widthAdjustment,
                        height: blockRect.height
                    )

                    drawCodeBlock(in: effectiveBlockRect.integral, with: cgContext, and: fillColor)
                }
            }
    }

    private func drawCodeBlock(in rect: CGRect, with context: CGContext, and fillColor: NSColor) {
        context.saveGState()

        let cornerRadius: CGFloat = 5,
            roundRectPath = CGPath(
                roundedRect: rect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )

        context.addPath(roundRectPath)

        context.setFillColor(fillColor.withAlphaComponent(0.1).cgColor)
        context.setStrokeColor(fillColor.cgColor)
        context.drawPath(using: .fillStroke)

        context.restoreGState()
    }
}

// MARK: - NSAttributedStringKey

extension NSAttributedString.Key {
    static let codeBlock = NSAttributedString.Key(rawValue: "CodeBlockAttributeName")
}
