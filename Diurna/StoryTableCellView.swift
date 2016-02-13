//
//  StoryTableCell.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 20/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryTableCellView : NSTableCellView {

    // MARK: Outlets
    @IBOutlet var contentView: NSTableCellView!
    @IBOutlet weak var readStatus: NSButton!
    @IBOutlet weak var title : NSTextField!
    @IBOutlet weak var by : NSTextField!
    @IBOutlet weak var URL: NSButton!
    @IBOutlet weak var comments : NSTextField!
    @IBOutlet weak var time: NSTextField!

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("StoryTableCellView", owner: self, topLevelObjects: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
        self.addSubview(content)
    }
}
