//
//  NSAttributedString+HtmlParser.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension NSAttributedString {
    // TODO: pass font attributes and the likes (like NSAttributedString)
    convenience init(htmlString: String) {
        let parser = HtmlParser(input: htmlString)
        self.init(attributedString: parser.attributedString())
    }
}