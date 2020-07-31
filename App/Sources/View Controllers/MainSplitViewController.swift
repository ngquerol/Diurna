//
//  MainSplitViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

class MainSplitViewController: NSSplitViewController {
    // MARK: Outlets

    @IBOutlet var sidebarSplitViewItem: NSSplitViewItem! {
        didSet {
            sidebarSplitViewItem.minimumThickness = 135
            sidebarSplitViewItem.maximumThickness = 135
        }
    }

    @IBOutlet var storiesSplitViewItem: NSSplitViewItem!

    @IBOutlet var storyDetailsSplitViewItem: NSSplitViewItem! {
        didSet {
            storyDetailsSplitViewItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
        }
    }

    // MARK: Properties

    private var sidebarCollapseObservation: NSKeyValueObservation?

    // MARK: View lifecycle

    override func viewWillAppear() {
        super.viewWillAppear()

        guard
            let storiesViewController =
                storiesSplitViewItem
                .viewController as? StoriesViewController
        else {
            return
        }

        // make room for close/minimize/fullscreen widgets if the sidebar is collapsed
        sidebarCollapseObservation =
            sidebarSplitViewItem
            .observe(\.isCollapsed) { splitViewItem, _ in
                // TODO: find a way to not hardcode offset, if possible
                storiesViewController.toolbarLeadingSpaceConstraint.constant +=
                    splitViewItem
                        .isCollapsed ? 75.0 : -75.0
            }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        sidebarCollapseObservation = nil
    }
}
