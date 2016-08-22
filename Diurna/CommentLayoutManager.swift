//
//  CommentLayoutManager.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/07/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

let CodeBlockAttributeName = "CodeBlockAttributeName"

class CommentLayoutManager: NSLayoutManager {

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage?.enumerateAttribute(CodeBlockAttributeName, in: charRange, options: []) { attributeValue, attributeRange, _ in
            if let codeBlockColor = attributeValue as? NSColor {
                drawCodeBlock(with: codeBlockColor, for: attributeRange, at: origin)
            }
        }
    }

    private func drawCodeBlock(with color: NSColor, for range: NSRange, at origin: NSPoint) {
        let activeRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

        guard let container = textContainer(forGlyphAt: activeRange.location, effectiveRange: nil) else { return }

        var textRect = boundingRect(
            forGlyphRange: activeRange,
            in: container
            ).offsetBy(dx: origin.x, dy: origin.y)

        textRect.origin.x -= 2.5
        textRect.size.width += 5.0

        if let context = NSGraphicsContext.current()?.cgContext {
            context.saveGState()

            let fillColor = color.blended(withFraction: 0.75, of: .white)!,
            strokeColor = color.blended(withFraction: 0.25, of: .white)!,
            path = NSBezierPath(roundedRect: textRect, xRadius: 3.0, yRadius: 3.0)

            context.setStrokeColor(strokeColor.cgColor)
            context.setFillColor(fillColor.cgColor)

            context.addPath(path.CGPath!)
            context.drawPath(using: .stroke)
            context.fill(textRect)

            context.restoreGState()
        }
    }
}

private extension NSBezierPath {
    var CGPath: CGPath? {
        get {
            guard elementCount != 0 else { return nil }

            let path = CGMutablePath()
            var didClosePath = false

            for i in 0..<self.elementCount {
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
                    didClosePath = true;
                }
            }

            if !didClosePath {
                path.closeSubpath()
            }
            
            return path.copy()
        }
    }
}
