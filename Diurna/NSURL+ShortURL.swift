//
//  NSURL+ShortURL.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension NSURL {
    func shortURL() -> String? {
        let undesirablePrefixesPattern = "^(www[0-9]*)\\."

        guard let host = self.host else {
            return nil
        }

        if let match = host.rangeOfString(undesirablePrefixesPattern, options: .RegularExpressionSearch) {
            return host.substringFromIndex(match.endIndex)
        }

        return host
    }
}