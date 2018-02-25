//
//  NoEmphasisTableRowView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/09/2019.
//  Copyright © 2019 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class NoEmphasisTableRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { false }
        set {}
    }
}
