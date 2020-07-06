//
//  CommentsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 22/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI
import OSLog

class CommentsViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet var scrollView: NSScrollView!

    @IBOutlet var outlineView: CommentsOutlineView! {
        didSet {
            prototypeCellView =
                outlineView.makeView(
                    withIdentifier: .commentCell,
                    owner: self
                ) as? CommentCellView
        }
    }

    // MARK: Properties

    override var representedObject: Any? {
        didSet {
            if let story = representedObject as? Story {
                updateComments(from: story)
            }
        }
    }

    var progressOverlayView: NSView?

    var placeholderView: NSView?

    private var story: Story? {
        return representedObject as? Story
    }

    private var commentsDataSource: [Comment] = [] {
        didSet {
            outlineView.reloadData()
        }
    }

    private var prototypeCellView: CommentCellView?

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .toggleCommentReplies,
            name: .toggleCommentRepliesNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: .scrollToParentComment,
            name: .goToParentCommentNotification,
            object: nil
        )
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Methods

    @objc func toggleCommentReplies(_ notification: Notification) {
        guard notification.name == .toggleCommentRepliesNotification,
            let cellView = notification.object as? CommentCellView,
            let comment = cellView.objectValue as? Comment,
            let toggleReplies = notification.userInfo?["toggleChildren"] as? Bool
        else {
            return
        }

        if outlineView.isItemExpanded(comment) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.allowsImplicitAnimation = true
                outlineView.collapseItem(comment, collapseChildren: toggleReplies)
            }
        } else {
            NSAnimationContext.runAnimationGroup(
                { _ in
                    outlineView.animator().expandItem(comment, expandChildren: toggleReplies)
                },
                completionHandler: {
                    //                let firstChild = self.outlineView.child(0, ofItem: comment)
                    //                let firstChildRowIndex = self.outlineView.row(forItem: firstChild)
                    // TODO: scroll row to visible / highlight
                }
            )
        }
    }

    @objc func goToParentComment(_ notification: Notification) {
        guard
            let comment = notification.userInfo?["childComment"] as? Comment
        else {
            return
        }

        let parentComment = outlineView.parent(forItem: comment)
        let parentCommentRowIndex = outlineView.row(forItem: parentComment)

        guard parentCommentRowIndex != -1 else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            outlineView.scrollRowToVisible(parentCommentRowIndex)
        }
    }

    private func updateComments(from story: Story) {
        guard
            let descendants = story.descendants,
            descendants != 0
        else {
            commentsDataSource = []
            showPlaceholder(withTitle: "No comments yet.")
            return
        }

        hidePlaceholder()

        showProgressOverlay(with: "Loading comments...")

        apiClient.fetchComments(of: story) { [weak self] commentsResults in
            let comments: [Comment] = commentsResults.compactMap {
                switch $0 {
                case let .success(comment): return comment
                case let .failure(error):
                    os_log(
                        "Failed to retrieve comment: %s",
                        log: .apiRequests,
                        type: .error,
                        error.localizedDescription
                    )
                    return nil
                }
            }

            self?.commentsDataSource = comments
            self?.outlineView.expandItem(nil, expandChildren: true)
            self?.outlineView.scrollRowToVisible(0)

            self?.hideProgressOverlay()
        }
    }
}

// MARK: - HNAPIConsumer

extension CommentsViewController: HNAPIConsumer {}

// MARK: - ProgressShowing

extension CommentsViewController: ProgressShowing {}

// MARK: - PlaceholderShowing

extension CommentsViewController: PlaceholderShowing {}

// MARK: - Selectors

extension Selector {
    fileprivate static let toggleCommentReplies = #selector(
        CommentsViewController
            .toggleCommentReplies(_:))

    fileprivate static let scrollToParentComment = #selector(
        CommentsViewController
            .goToParentComment(_:))
}

// MARK: - NSOutlineView Data Source

extension CommentsViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil else { return commentsDataSource.count }

        guard
            let comment = item as? Comment,
            let kids = comment.kids
        else {
            return 0
        }

        return kids.count
    }

    func outlineView(_: NSOutlineView, isItemExpandable: Any) -> Bool {
        guard
            let comment = isItemExpandable as? Comment,
            let kids = comment.kids
        else {
            return false
        }
        return !kids.isEmpty
    }

    func outlineView(
        _: NSOutlineView, objectValueFor _: NSTableColumn?,
        byItem item: Any?
    ) -> Any? {
        return item as? Comment
    }

    func outlineView(_: NSOutlineView, child: Int, ofItem: Any?) -> Any {
        guard
            let comment = ofItem as? Comment,
            let kids = comment.kids
        else {
            return commentsDataSource[child]
        }
        return kids[child]
    }
}

// MARK: - NSOutlineView Delegate

extension CommentsViewController: NSOutlineViewDelegate {
    // TODO: Implement row height cache (with proper eviction and size approximation)
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard
            let comment = item as? Comment,
            let dummyCellView = prototypeCellView
        else {
            return outlineView.rowHeight
        }

        let cellLevel = CGFloat(outlineView.level(forItem: comment))
        let availableWidth =
            outlineView.bounds.width - (outlineView.indentationPerLevel * cellLevel)

        dummyCellView.bounds.size = NSSize(width: availableWidth, height: 0)
        dummyCellView.objectValue = comment
        dummyCellView.layoutSubtreeIfNeeded()

        return dummyCellView.fittingSize.height
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView?
    {
        let comment = item as? Comment
        let cellView =
            outlineView.makeView(withIdentifier: .commentCell, owner: self)
            as? CommentCellView

        cellView?.objectValue = comment
        cellView?.isExpandable = outlineView.isExpandable(comment)
        cellView?.isExpanded =
            (cellView?.isExpandable ?? false)
            && outlineView.isItemExpanded(
                comment)
        cellView?.opBadgeView.isHidden = comment?.by != story?.by

        let repliesCount = self.outlineView.numberOfDescendants(ofItem: comment)
        cellView?.repliesTextField.stringValue =
            "\(repliesCount) " + (repliesCount > 1 ? "replies" : "reply") + " hidden"
        cellView?.replyArrowTextField.isHidden = outlineView.parent(forItem: comment) == nil

        return cellView
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem _: Any) -> NSTableRowView? {
        return outlineView.makeView(withIdentifier: .commentRow, owner: self) as? CommentRowView
    }

    func outlineView(_: NSOutlineView, shouldSelectItem _: Any) -> Bool {
        return false
    }

    func outlineViewColumnDidResize(_: Notification) {
        let wholeRowsIndexes: IndexSet = IndexSet(integersIn: 0..<outlineView.numberOfRows)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            outlineView.noteHeightOfRows(
                withIndexesChanged: wholeRowsIndexes
            )
        }
    }
}
