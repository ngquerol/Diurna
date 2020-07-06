//
//  NSOutlineView+Additions.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 02/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

extension NSOutlineView {
    func children(ofItem item: Any?) -> [Any?] {
        let childCount = numberOfChildren(ofItem: item)

        if childCount == 0 { return [] }

        return (0..<childCount).map { child($0, ofItem: item) }
    }

    func numberOfDescendants(ofItem item: Any?) -> Int {
        let childCount = numberOfChildren(ofItem: item)

        guard childCount > 0 else { return 0 }

        var descendantCount = childCount,
            stack = children(ofItem: item)

        while let child = stack.popLast() {
            descendantCount += numberOfChildren(ofItem: child)
            stack.append(contentsOf: children(ofItem: child))
        }

        return descendantCount
    }
}
