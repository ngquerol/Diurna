//
//  URL+ShortURL.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension URL {
    /// This URL, stripped of all its components except its host and top-level domain.
    /// `nil` if there is no host (i.e. the URL is relative)
    var shortURL: String? {
        let undesirablePrefixesPattern = "^(www[0-9]*)\\."

        guard let host = host else {
            return nil
        }

        if let match = host.range(of: undesirablePrefixesPattern, options: .regularExpression) {
            return String(host[match.upperBound...])
        }

        return host
    }
}
