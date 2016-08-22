//
//  MainSplitViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {

    @IBOutlet weak var sidebarSplitViewItem: NSSplitViewItem! {
        didSet {
            sidebarSplitViewItem.minimumThickness = 68.0
            sidebarSplitViewItem.maximumThickness = 68.0

            sidebarSplitViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
    }
    @IBOutlet weak var storiesSplitViewItem: NSSplitViewItem!
    @IBOutlet weak var detailSplitViewItem: NSSplitViewItem! {
        didSet {
            detailSplitViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
    }

    // MARK: View lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .openStoryDetailsPane,
            name: .storySelectionNotification,
            object: nil
        )
    }

    // MARK: Methods
    func openStoryDetailsPane(_ notification: Notification) {
        guard notification.name == .storySelectionNotification else { return }

        if detailSplitViewItem.isCollapsed {
            detailSplitViewItem.animator().isCollapsed = false
        }
    }
}

// MARK: - Selectors
private extension Selector {
    static let openStoryDetailsPane = #selector(MainSplitViewController.openStoryDetailsPane(_:))
}
