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
        return input.substring(from: pos).hasPrefix(s)
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

struct MarkupParserConfiguration {
    var regularFont: NSFont = .systemFont(ofSize: 12.0)
    var monospaceFont: NSFont = NSFont(name: "Menlo", size: 11.0)!
    var textAlignment: NSTextAlignment = .natural
}

struct MarkupParser {
    private var parser: Parser
    private var parserConfiguration: MarkupParserConfiguration

    init(input: String) {
        parser = Parser(inputString: input)
        parserConfiguration = MarkupParserConfiguration()
    }

    init(input: String, configuration: MarkupParserConfiguration) {
        parser = Parser(inputString: input)
        parserConfiguration = configuration
    }

    private mutating func parseTagName() -> String {
        var tagCharacterSet = CharacterSet(charactersIn: "/")
        tagCharacterSet.formUnion(CharacterSet.alphanumerics)
        return parser.consumeWhile { $0.isMemberOf(tagCharacterSet) }
    }

    private mutating func parseText() -> String {
        return CFXMLCreateStringByUnescapingEntities(
            nil,
            parser.consumeWhile { $0 != "<" } as CFString!,
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
            guard let urlString = tag.attributes["href"],
                let url = URL(string: urlString) else {
                return [.font: parserConfiguration.regularFont]
            }

            return [
                .link: url as Any,
                .font: parserConfiguration.regularFont,
                .foregroundColor: Themes.current.urlColor,
                .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            ]

        case "i":
            return [
                .font: NSFontManager.shared.convert(
                    parserConfiguration.regularFont,
                    toHaveTrait: .italicFontMask
                ),
            ]

        case "code":
            let paragraphStyle = NSMutableParagraphStyle()

            paragraphStyle.lineBreakMode = .byCharWrapping

            return [
                .font: parserConfiguration.monospaceFont,
                .codeBlock: Themes.current.codeBlockColor,
                .paragraphStyle: paragraphStyle
            ]

        case "p": fallthrough

        case _:
            return [.font: parserConfiguration.regularFont]
        }
    }

    private mutating func handleTag(_ result: NSMutableAttributedString) -> [NSAttributedStringKey: Any] {
        let tag = parseTag()

        if tag.name == "p" {
            result.append(NSAttributedString(string: "\n\n"))
        }

        return getFormattingAttributes(for: tag)
    }

    private mutating func handleText(_ result: NSMutableAttributedString, formattingAttributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
            return NSAttributedString(
                string: parseText(),
                attributes: formattingAttributes
            )
    }

    mutating func toAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()
        var formattingAttributes: [NSAttributedStringKey: Any] = [
            .font: parserConfiguration.regularFont
        ]

        result.beginEditing()

        while !parser.eof() {
            switch parser.nextCharacter() {
            case "<": formattingAttributes = handleTag(result)
            case _: result.append(handleText(result, formattingAttributes: formattingAttributes))
            }
        }

        result.endEditing()

        return result
    }
}
