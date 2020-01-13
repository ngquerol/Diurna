//
//  StoryMasterView.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/11/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoryMasterViewController: NSViewController {

    // MARK: Properties

    private var detailsViewController: StoryDetailsViewController? {
        didSet {
            detailsViewController?.view.isHidden = true
        }
    }

    private var commentsViewController: CommentsViewController? {
        didSet {
            commentsViewController?.view.isHidden = true
        }
    }

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

    @objc func showStory(_ notification: Notification) {
        guard
            notification.name == .storySelectionNotification,
            let story = notification.userInfo?["story"] as? Story
        else {
            return
        }

        detailsViewController?.selectedStory = story
        commentsViewController?.selectedStory = story

        detailsViewController?.view.isHidden = false
        commentsViewController?.view.isHidden = false
    }
}

// MARK: - Selectors

private extension Selector {
    static let showStory = #selector(StoryMasterViewController.showStory(_:))
}
