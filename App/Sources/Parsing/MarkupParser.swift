//
//  MarkupParser.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 12/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

extension Character {
    fileprivate func isMemberOf(_ set: CharacterSet) -> Bool {
        let bridgedCharacter = String(self).unicodeScalars.first!
        return set.contains(bridgedCharacter)
    }
}

private struct Parser {
    private var pos: String.Index
    private let input: String

    init(inputString: String) {
        input = inputString
        pos = input.startIndex
    }

    func nextCharacter() -> Character {
        return input[pos]
    }

    func startsWith(_ s: String) -> Bool {
        return input[pos...].hasPrefix(s)
    }

    func eof() -> Bool {
        return pos >= input.endIndex
    }

    @discardableResult
    mutating func consumeCharacter() -> Character {
        let char = input[pos]
        pos = input.index(after: pos)
        return char
    }

    @discardableResult
    mutating func consumeWhile(_ predicate: (Character) -> Bool) -> String {
        var result = String()
        while !eof(), predicate(nextCharacter()) { result.append(consumeCharacter()) }
        return result
    }

    mutating func consumeWhitespace() {
        consumeWhile { $0.isMemberOf(CharacterSet.whitespaces) }
    }
}

private struct Tag {
    let name: String
    let attributes: [String: String]
}

struct MarkupParser {
    private let leadingSpaceRegex: NSRegularExpression = {
        try! NSRegularExpression(
            pattern: "^(\\s{2,4})(\\S.*)$",
            options: .anchorsMatchLines
        )
    }()

    private let codeParagraphStyle: NSParagraphStyle = {
        let codeParagraphStyle = NSMutableParagraphStyle()
        codeParagraphStyle.lineBreakMode = .byCharWrapping
        codeParagraphStyle.headIndent = 10.0
        codeParagraphStyle.firstLineHeadIndent = 10.0
        codeParagraphStyle.tailIndent = -10.0
        codeParagraphStyle.paragraphSpacing = 5.0
        codeParagraphStyle.paragraphSpacingBefore = 5.0
        return codeParagraphStyle
    }()

    private var parser: Parser

    init(input: String) {
        parser = Parser(inputString: input)
    }

    private mutating func parseTagName() -> String {
        var tagCharacterSet = CharacterSet(charactersIn: "/")
        tagCharacterSet.formUnion(CharacterSet.alphanumerics)
        return parser.consumeWhile { $0.isMemberOf(tagCharacterSet) }
    }

    private mutating func parseText() -> String {
        return CFXMLCreateStringByUnescapingEntities(
            nil,
            parser.consumeWhile { $0 != "<" } as CFString,
            nil
        ) as String
    }

    private mutating func parseAttribute() -> (String, String) {
        let name = parseTagName()
        parser.consumeCharacter()
        let value = parseAttributeValue()

        return (name, value)
    }

    private mutating func parseAttributeValue() -> String {
        let openQuote = parser.consumeCharacter()
        let unescapedValue = parser.consumeWhile { $0 != openQuote }
        let value =
            CFXMLCreateStringByUnescapingEntities(
                nil,
                unescapedValue as CFString,
                nil
            ) as String

        parser.consumeCharacter()

        return value
    }

    private mutating func parseAttributes() -> [String: String] {
        var attributes: [String: String] = [:]

        while parser.nextCharacter() != ">" {
            parser.consumeWhitespace()
            let (name, value) = parseAttribute()
            attributes[name] = value
        }

        return attributes
    }

    private mutating func parseTag() -> Tag {
        parser.consumeCharacter()
        let name = parseTagName()
        let attributes = parseAttributes()
        parser.consumeCharacter()

        return Tag(
            name: name,
            attributes: attributes
        )
    }

    private func getFormattingAttributes(for tag: Tag?) -> [NSAttributedString.Key: Any] {
        let defaultFormattingAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.textColor,
        ]

        switch tag?.name {
        case "a":
            guard
                let urlString = tag?.attributes["href"],
                let url = URL(string: urlString)
            else {
                return defaultFormattingAttributes
            }

            return defaultFormattingAttributes.merging(
                [
                    .link: url,
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], uniquingKeysWith: { $1 }
            )

        case "i":
            return defaultFormattingAttributes.merging(
                [
                    .font: NSFontManager.shared.convert(
                        NSFont.systemFont(ofSize: 12),
                        toHaveTrait: .italicFontMask
                    )
                ], uniquingKeysWith: { $1 }
            )

        case "code":
            return defaultFormattingAttributes.merging(
                [
                    .font: NSFont.userFixedPitchFont(ofSize: 11)!,
                    .codeBlock: NSColor.lightGray,
                    .paragraphStyle: codeParagraphStyle,
                ], uniquingKeysWith: { $1 }
            )

        case _:
            return defaultFormattingAttributes
        }
    }

    private mutating func handleTag(_ result: NSMutableAttributedString) -> Tag {
        let tag = parseTag()

        if tag.name == "p" {
            result.append(NSAttributedString(string: "\n\n"))
        }

        return tag
    }

    private mutating func handleText(for tag: Tag?) -> NSAttributedString {
        let formattingAttributes = getFormattingAttributes(for: tag)
        var text = parseText()

        if tag?.name == "code" {
            let wholeTextRange = NSRange(0..<text.count)

            text = leadingSpaceRegex.stringByReplacingMatches(
                in: text,
                options: [],
                range: wholeTextRange,
                withTemplate: "$2"
            )
        }

        return NSAttributedString(
            string: text,
            attributes: formattingAttributes
        )
    }

    mutating func toAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()
        var currentTag: Tag?

        result.beginEditing()

        while !parser.eof() {
            switch parser.nextCharacter() {
            case "<": currentTag = handleTag(result)
            case _: result.append(handleText(for: currentTag))
            }
        }

        result.endEditing()

        return result
    }
}
