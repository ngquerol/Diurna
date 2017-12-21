//
//  CategoryTableRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 29/05/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CategoryRowView: NSTableRowView {

    // MARK: Properties
    override var isEmphasized: Bool {
        get {
            // this disables the default blue highlight
            return false
        }

        set {}
    }
}

// MARK: - NSUserInterfaceItemIdentifier
extension NSUserInterfaceItemIdentifier {
    static let categoryRow = NSUserInterfaceItemIdentifier("CategoryRow")
}
