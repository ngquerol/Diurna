//
//  MarkupParser.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 12/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

extension Character {
    func isMemberOf(set: NSCharacterSet) -> Bool {
        let bridgedCharacter = (String(self) as NSString).characterAtIndex(0)
        return set.characterIsMember(bridgedCharacter)
    }
}

struct Parser {
    private var pos: String.Index
    private let input: String

    init(inputString: String) {
        self.input = inputString
        self.pos = self.input.startIndex
    }

    func nextCharacter() -> Character {
        return input[self.pos]
    }

    func startsWith(s: String) -> Bool {
        return self.input.substringFromIndex(self.pos).hasPrefix(s)
    }

    func eof() -> Bool {
        return self.pos >= self.input.endIndex
    }

    mutating func consumeCharacter() -> Character {
        let char = self.input[self.pos]
        self.pos = self.pos.successor()
        return char
    }

    mutating func consumeWhile(predicate: Character -> Bool) -> String {
        var result = String()
        while !self.eof() && predicate(self.nextCharacter()) { result.append(consumeCharacter()) }
        return result
    }

    mutating func consumeWhitespace() {
        self.consumeWhile { $0.isMemberOf(NSCharacterSet.whitespaceCharacterSet()) }
    }
}

class MarkupParser {
    private var parser: Parser

    init(input: String) {
        self.parser = Parser(inputString: input)
    }

    struct Tag {
        let name: String
        let attributes: [String: String]
    }

    private func parseTagName() -> String {
        let tagCharacterSet = NSMutableCharacterSet(charactersInString: "/")
        tagCharacterSet.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet())
        return parser.consumeWhile { $0.isMemberOf(tagCharacterSet) }
    }

    private func parseText() -> String {
        return CFXMLCreateStringByUnescapingEntities(
            nil,
            parser.consumeWhile { $0 != "<" },
            nil
        ) as String
    }

    private func parseAttribute() -> (String, String) {
        let name = self.parseTagName()
        parser.consumeCharacter()
        let value = self.parseAttributeValue()
        return (name, value)
    }

    private func parseAttributeValue() -> String {
        let openQuote = parser.consumeCharacter(),
            value = CFXMLCreateStringByUnescapingEntities(
                nil,
                parser.consumeWhile { $0 != openQuote },
                nil
        )
        parser.consumeCharacter()
        return value as String
    }

    private func parseAttributes() -> [String: String] {
        var attributes: [String: String] = [:]

        while parser.nextCharacter() != ">" {
            parser.consumeWhitespace()
            let (name, value) = self.parseAttribute()
            attributes[name] = value
        }

        return attributes
    }

    private func parseTag() -> Tag {
        parser.consumeCharacter()
        let name = self.parseTagName()
        let attributes = self.parseAttributes()
        parser.consumeCharacter()

        return Tag(
            name: name,
            attributes: attributes
        )
    }

    private func tagToFormattingOptions(tag: Tag) -> [String: AnyObject]? {
        let defaultFormatting = [NSFontAttributeName: NSFont.systemFontOfSize(12.0)]

        switch tag.name {

        case "p":
            return defaultFormatting

        case "a":
            guard let urlString = tag.attributes["href"],
                url = NSURL(string: urlString) else {
                    return [:]
            }

            return [
                NSLinkAttributeName: url,
                NSFontAttributeName: NSFont.systemFontOfSize(12.0),
                NSForegroundColorAttributeName: NSColor.blueColor(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue
            ]

        case "i":
            return [
                NSFontAttributeName: NSFontManager.sharedFontManager().convertFont(
                    NSFont.systemFontOfSize(12.0),
                    toHaveTrait: .ItalicFontMask
                )
            ]

        case "pre", "code":
            return [NSFontAttributeName: NSFont(name: "Menlo", size: 11.0) ?? NSFont.systemFontOfSize(11.0)]

        case _: return defaultFormatting
        }
    }

    func toAttributedString() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let paragraphFormattingOptions = NSMutableParagraphStyle()

        var formattingOptions: [String: AnyObject]? = [
            NSFontAttributeName: NSFont.systemFontOfSize(12.0),
            NSParagraphStyleAttributeName: paragraphFormattingOptions
        ]

        while !parser.eof() {
            switch parser.nextCharacter() {

            case "<":
                let tag = self.parseTag()
                formattingOptions = tagToFormattingOptions(tag)
                if tag.name == "p" {
                    result.appendAttributedString(
                        NSAttributedString(string: "\u{2028}\u{2028}", attributes: formattingOptions)
                    )
                }

            case _:
                result.appendAttributedString(
                    NSAttributedString(
                        string: self.parseText(),
                        attributes: formattingOptions
                    )
                )
            }
        }

        return result
    }
}