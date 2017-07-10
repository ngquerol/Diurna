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
    // this disables the default blue highlight
    override var isEmphasized: Bool {
        get {
            return false
        }

        set {}
    }
}

// MARK: - Reusable
extension CategoryRowView: Reusable {

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("CategoryRow")
}
