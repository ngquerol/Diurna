//
//  NSOutlineView+ViewForItem.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 23/08/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

extension NSOutlineView {

    func viewFor(item: Any?) -> Any? {
        let viewRow = row(forItem: item)

        guard 0 ..< numberOfRows ~= viewRow,
            let cellView = view(atColumn: 0, row: viewRow, makeIfNecessary: false) as? CommentCellView else {
            return nil
        }

        return cellView
    }
}
