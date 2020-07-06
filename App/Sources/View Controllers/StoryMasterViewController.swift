//
//  StoryMasterView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/11/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI

class StoryMasterViewController: NSSplitViewController {
    // MARK: Properties

    var placeholderView: NSView?

    private var detailsViewController: StoryDetailsViewController?

    private var commentsViewController: CommentsViewController?

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard
            let detailsViewController = children.first as? StoryDetailsViewController,
            let commentsViewController = children.last as? CommentsViewController
        else {
            return
        }

        self.detailsViewController = detailsViewController
        self.commentsViewController = commentsViewController

        showPlaceholder(withTitle: "No story selected.")
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .showStory,
            name: .storySelectionNotification,
            object: nil
        )
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Methods

    override func splitView(
        _: NSSplitView, effectiveRect _: NSRect, forDrawnRect _: NSRect,
        ofDividerAt _: Int
    ) -> NSRect {
        return .zero  // hide the drag mouse cursor
    }

    @objc func showStory(_ notification: Notification) {
        guard let story = notification.userInfo?["story"] as? Story else { return }
        children.forEach { $0.representedObject = story }
        hidePlaceholder()
    }
}

// MARK: - Selectors

extension Selector {
    fileprivate static let showStory = #selector(StoryMasterViewController.showStory(_:))
}

// MARK: - PlaceholderShowing

extension StoryMasterViewController: PlaceholderShowing {}
