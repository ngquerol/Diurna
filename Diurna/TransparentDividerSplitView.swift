//
//  TransparentDividerSplitView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class TransparentDividerSplitView: NSSplitView {

    // MARK: Properties

    override var dividerColor: NSColor {
        return Themes.current.dividerColor
    }
}
