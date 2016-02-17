//
//  CommentParser.swift
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
    var pos: String.Index
    let input: String
}

extension Parser {

    init(htmlString: String) {
        self.input = htmlString
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
        var result = ""
        while !self.eof() && predicate(self.peekCharacter()) {
            result.append(consumeCharacter())
        }
        return result
    }

    mutating func consumeWhitespace() {
        self.consumeWhile({ $0.isMemberOf(NSCharacterSet.whitespaceCharacterSet())})
    }

    mutating func parseTagName() -> String {
        consumeCharacter()
        let tagName = consumeWhile({ $0.isMemberOf(NSCharacterSet.alphanumericCharacterSet())})
        consumeWhile({ $0 != ">"})
        consumeCharacter()
        return tagName
    }

    mutating func parseText() -> String {
        return CFXMLCreateStringByUnescapingEntities(nil, self.consumeWhile({ $0 != "<"}), nil) as String
    }
}

class CommentParser {

    class func parseFromHTMLString(htmlString: String) -> NSAttributedString {
        let attrStr = NSMutableAttributedString()

        var parser = Parser(htmlString: htmlString)

        while !parser.eof() {
            switch parser.peekCharacter() {

            case "<":
                let tag = parser.parseTagName()

                switch tag {

                case "p":
                    attrStr.appendAttributedString(
                        NSAttributedString(string: "\r\n\r\n",
                            attributes: [
                                NSFontAttributeName: NSFont.systemFontOfSize(12.0)
                        ])
                    )
                    break

                case "a":
                    let url = parser.parseText()
                    attrStr.appendAttributedString(
                        NSAttributedString(string: url,
                            attributes: [
                                NSLinkAttributeName: NSURL(string: url)!,
                                NSFontAttributeName: NSFont.systemFontOfSize(12.0)
                        ])
                    )
                    break

                case "i":
                    attrStr.appendAttributedString(
                        NSAttributedString(string: parser.parseText(),
                            attributes: [
                                NSFontAttributeName: NSFont.systemFontOfSize(12.0, weight: NSFontWeightMedium)
                        ])
                    )
                    break

                case "pre":
                    parser.parseTagName()
                    attrStr.appendAttributedString(
                        NSAttributedString(string: parser.parseText(),
                            attributes: [
                                NSFontAttributeName: NSFont(name: "Menlo", size: 11.0) ?? NSFont.systemFontOfSize(11.0)
                        ])
                    )
                    break

                case _: break
                }
                break

            case _:
                attrStr.appendAttributedString(NSAttributedString(string: parser.parseText(),
                    attributes: [
                        NSFontAttributeName: NSFont.systemFontOfSize(12.0)
                    ]))
                break
            }
        }

        return attrStr
    }
}
