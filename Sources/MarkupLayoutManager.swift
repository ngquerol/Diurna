//
//  MarkupLayoutManager.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

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

        textStorage.enumerateAttribute(.codeBlock, in: characterRange, options: []) { value, range, _ in
            guard value != nil else { return }

            let blockGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var blockRect: CGRect?

            enumerateLineFragments(forGlyphRange: blockGlyphRange) { rect, _, _, _, _ in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                blockRect = blockRect == nil ? lineRect : blockRect?.union(lineRect)
            }

            if let blockRect = blockRect {
                let widthAdjustment: CGFloat = 5,
                    effectiveBlockRect = NSRect(
                        x: blockRect.origin.x + widthAdjustment / 2,
                        y: blockRect.origin.y,
                        width: blockRect.width - widthAdjustment,
                        height: blockRect.height
                    )

                drawCodeBlock(in: effectiveBlockRect.integral, with: cgContext)
            }
        }
    }

    private func drawCodeBlock(in rect: CGRect, with context: CGContext) {
        guard let roundRectPath = NSBezierPath(roundedRect: rect, xRadius: 2.5, yRadius: 2.5).cgPath else {
            return
        }

        context.saveGState()

        context.addPath(roundRectPath)
        context.setFillColor(Themes.current.codeBlockColor.cgColor)
        context.setStrokeColor(Themes.current.dividerColor.cgColor)
        context.drawPath(using: .fillStroke)

        context.restoreGState()
    }
}

// MARK: - NSBezierPath

private extension NSBezierPath {
    var cgPath: CGPath? {
        guard elementCount != 0 else { return nil }

        let path = CGMutablePath()
        var didClosePath = false

        for i in 0 ..< elementCount {
            var points = [NSPoint](repeating: NSZeroPoint, count: 3)

            switch element(at: i, associatedPoints: &points) {
            case .moveToBezierPathElement:
                path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            case .lineToBezierPathElement:
                path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            case .curveToBezierPathElement:
                path.addCurve(
                    to: CGPoint(x: points[2].x, y: points[2].y),
                    control1: CGPoint(x: points[0].x, y: points[0].y),
                    control2: CGPoint(x: points[1].x, y: points[1].y)
                )
            case .closePathBezierPathElement:
                path.closeSubpath()
                didClosePath = true
            }
        }

        if !didClosePath {
            path.closeSubpath()
        }

        return path.copy()
    }
}

// MARK: - NSAttributedStringKey

extension NSAttributedStringKey {
    static let codeBlock = NSAttributedStringKey(rawValue: "CodeBlockAttributeName")
}
