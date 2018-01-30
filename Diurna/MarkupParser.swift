//
//  MarkupParser.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 12/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

private extension Character {
    func isMemberOf(_ set: CharacterSet) -> Bool {
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
        while !eof() && predicate(nextCharacter()) { result.append(consumeCharacter()) }
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
    private var parser: Parser
    private let leadingSpaceRegex = try! NSRegularExpression(
        pattern: "^(\\s{2,4})(\\S.*)$",
        options: .anchorsMatchLines
    )

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
        let openQuote = parser.consumeCharacter(),
            unescapedValue = parser.consumeWhile { $0 != openQuote },
            value = CFXMLCreateStringByUnescapingEntities(
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
        let name = parseTagName(),
            attributes = parseAttributes()
        parser.consumeCharacter()

        return Tag(
            name: name,
            attributes: attributes
        )
    }

    private func getFormattingAttributes(for tag: Tag) -> [NSAttributedStringKey: Any] {
        switch tag.name {
        case "a":
            guard
                let urlString = tag.attributes["href"],
                let url = URL(string: urlString)
            else {
                return [.font: Themes.current.regularFont]
            }

            return [
                .link: url as Any,
                .font: Themes.current.regularFont,
                .foregroundColor: Themes.current.urlColor,
                .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            ]

        case "i":
            return [
                .font: NSFontManager.shared.convert(
                    Themes.current.regularFont,
                    toHaveTrait: .italicFontMask
                ),
            ]

        case "code":
            let paragraphStyle = NSMutableParagraphStyle(),
                font = Themes.current.monospaceFont

            paragraphStyle.lineBreakMode = .byCharWrapping
            paragraphStyle.headIndent = 10.0
            paragraphStyle.firstLineHeadIndent = 10.0
            paragraphStyle.tailIndent = -10.0
            paragraphStyle.paragraphSpacing = 5.0
            paragraphStyle.paragraphSpacingBefore = 5.0

            return [
                .font: font,
                .codeBlock: Themes.current.codeBlockColor,
                .paragraphStyle: paragraphStyle,
            ]

        case _:
            return [
                .font: Themes.current.regularFont,
                .foregroundColor: Themes.current.normalTextColor,
            ]
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
        var formattingAttributes: [NSAttributedStringKey: Any]

        if let tag = tag {
            formattingAttributes = getFormattingAttributes(for: tag)
        } else {
            formattingAttributes = [.font: Themes.current.regularFont]
        }

        var text = parseText()

        if tag?.name == "code" {
            let wholeTextRange = NSRange(0 ..< text.count)

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
