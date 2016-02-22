//
//  HtmlParser.swift
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

    func peekCharacter() -> Character {
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
        while !self.eof() && predicate(self.peekCharacter()) { result.append(consumeCharacter()) }
        return result
    }

    mutating func consumeWhitespace() {
        self.consumeWhile { $0.isMemberOf(NSCharacterSet.whitespaceCharacterSet()) }
    }
}

class HtmlParser {
    private var parser: Parser

    init(input: String) {
        self.parser = Parser(inputString: input)
    }

    private func consumeTagName() -> String {
        parser.consumeCharacter()
        let tagName = parser.consumeWhile {
            $0.isMemberOf(NSCharacterSet.alphanumericCharacterSet())
        }
        parser.consumeWhile { $0 != ">" }
        parser.consumeCharacter()
        return tagName
    }

    private func consumeText() -> String {
        return CFXMLCreateStringByUnescapingEntities(
            nil,
            parser.consumeWhile { $0 != "<" },
            nil
        ) as String
    }

    func attributedString() -> NSAttributedString {
        let attrStr = NSMutableAttributedString()

        while !parser.eof() {
            let char = parser.peekCharacter()

            if char == "<" {
                let tag = consumeTagName()

                switch tag {

                case "p":
                    attrStr.appendAttributedString(
                        NSAttributedString(
                            string: "\r\n\r\n",
                            attributes: [NSFontAttributeName: NSFont.systemFontOfSize(12.0)]
                        )
                    )
                    break

                case "a":
                    let urlString = consumeText()

                    guard let url = NSURL(string: urlString) else {
                        attrStr.appendAttributedString(
                            NSAttributedString(string: urlString)
                        )
                        break
                    }

                    attrStr.appendAttributedString(
                        NSAttributedString(
                            string: urlString,
                            attributes: [
                                NSLinkAttributeName: url,
                                NSFontAttributeName: NSFont.systemFontOfSize(12.0),
                                NSForegroundColorAttributeName: NSColor.blueColor(),
                                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue
                            ]
                        )
                    )
                    break

                case "i":
                    attrStr.appendAttributedString(
                        NSAttributedString(
                            string: consumeText(),
                            attributes: [
                                NSFontAttributeName: NSFontManager.sharedFontManager().convertFont(
                                    NSFont.systemFontOfSize(12.0),
                                    toHaveTrait: .ItalicFontMask
                                )
                            ]
                        )
                    )
                    break

                case "pre":
                    consumeTagName()
                    attrStr.appendAttributedString(
                        NSAttributedString(
                            string: consumeText(),
                            attributes: [
                                NSFontAttributeName: NSFont(name: "Menlo", size: 11.0) ?? NSFont.systemFontOfSize(11.0)
                            ]
                        )
                    )
                    break

                case _: break
                }
            } else {
                attrStr.appendAttributedString(
                    NSAttributedString(
                        string: consumeText(),
                        attributes: [
                            NSFontAttributeName: NSFont.systemFontOfSize(12.0)
                        ]
                    )
                )
            }
        }

        return attrStr
    }
}
