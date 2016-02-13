//
//  CommentTableCellView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 26/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentTableCellView : NSTableCellView {

    // MARK: Outlets
    @IBOutlet var contentView: NSTableCellView!
    @IBOutlet weak var author: NSTextField!
    @IBOutlet weak var time: NSTextField!
    @IBOutlet weak var text: NSTextField!
    
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
        NSBundle.mainBundle().loadNibNamed("CommentTableCellView", owner: self, topLevelObjects: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
//        text.wantsLayer = true
//        text.layer?.masksToBounds = true
//        text.layer?.backgroundColor = CGColorCreateGenericGray(0.3, 1.0)
//        text.layer?.borderWidth = 1.0
//        text.layer?.borderColor = NSColor.whiteColor().CGColor
//        text.layer?.cornerRadius = 5.0
        self.addSubview(content)
    }
}