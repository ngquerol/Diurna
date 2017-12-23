//
//  MainSplitViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {

    // MARK: Outlets

    @IBOutlet var sidebarSplitViewItem: NSSplitViewItem! {
        didSet {
            sidebarSplitViewItem.minimumThickness = 68.0
            sidebarSplitViewItem.maximumThickness = 68.0
            sidebarSplitViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
    }

    @IBOutlet var storiesSplitViewItem: NSSplitViewItem!

    @IBOutlet var storySplitViewItem: NSSplitViewItem! {
        didSet {
            storySplitViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
    }
}
