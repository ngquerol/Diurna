//
//  StoryTableCell.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 20/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryTableCellView: NSTableCellView {

    // MARK: Outlets
    @IBOutlet var contentView: NSTableCellView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var byTextField: NSTextField!
    @IBOutlet weak var URLButton: NSButton!
    @IBOutlet weak var commentsTextField: NSTextField!
    @IBOutlet weak var timeTextField: NSTextField!

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

    // MARK: Methods
    @IBAction private func visitURL(sender: NSButton) {
        guard let story = self.objectValue as? Story where story.url != nil,
            let url = story.url else {
                return
        }

        NSWorkspace.sharedWorkspace().openURL(url)
    }
}
