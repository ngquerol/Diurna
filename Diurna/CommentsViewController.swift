//
//  CommentsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 22/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentsViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet weak var commentsScrollView: NSScrollView! {
        didSet {
            commentsScrollView.backgroundColor = Themes.current.backgroundColor
        }
    }

    @IBOutlet weak var commentsOutlineView: CommentsOutlineView! {
        didSet {
            commentsOutlineView.backgroundColor = Themes.current.backgroundColor
            prototypeCellView = commentsOutlineView.makeView(
                withIdentifier: .commentCell,
                owner: self
            ) as? CommentCellView
        }
    }

    @IBOutlet weak var progressOverlay: ProgressOverlayView! {
        didSet {
            progressOverlay.isHidden = true
            progressOverlay.progressMessage.stringValue = "Loading comments..."
            progressOverlay.progressIndicator.maxValue = 1.0
        }
    }

    @IBOutlet weak var commentsPlaceholder: NSTextField! {
        didSet {
            commentsPlaceholder.isHidden = true
        }
    }

    // MARK: Properties
    var selectedStory: Story? {
        didSet {
            updateComments()
        }
    }

    private var commentsDataSource: [Comment] = [] {
        didSet {
            commentsOutlineView.reloadData()
        }
    }

    private var prototypeCellView: CommentCellView?
    
    private var progressObservation: NSKeyValueObservation?

    // MARK: View Lifecycle
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
            let toggleReplies = notification.userInfo?["toggleChildren"] as? Bool else {
            return
        }

        if commentsOutlineView.isItemExpanded(comment) {
            commentsOutlineView.animator().collapseItem(comment, collapseChildren: toggleReplies)
        } else {
            commentsOutlineView.animator().expandItem(comment, expandChildren: toggleReplies)
        }
    }

    @objc func goToParentComment(_ notification: Notification) {
        guard
            let comment = notification.userInfo?["childComment"] as? Comment
        else {
            return
        }

        let parentComment = commentsOutlineView.parent(forItem: comment),
            parentCommentRowIndex = commentsOutlineView.row(forItem: parentComment)

        guard parentCommentRowIndex != -1 else {
            return
        }

        commentsOutlineView.flashRow(
            at: parentCommentRowIndex,
            with: Themes.current.cellHighlightForegroundColor.blended(withFraction: 0.75, of: .white)!
        )
    }

    private func updateComments() {
        guard let story = selectedStory else {
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        commentsScrollView.isHidden = true
        NSAnimationContext.endGrouping()

        guard story.descendants != 0 else {
            commentsDataSource = []
            commentsPlaceholder.animator().isHidden = false
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        progressOverlay.isHidden = false
        commentsPlaceholder.isHidden = true
        NSAnimationContext.endGrouping()

        let progress = Progress(totalUnitCount: Int64(story.descendants ?? -1))

        progress.becomeCurrent(withPendingUnitCount: Int64(story.descendants ?? -1))

        progressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) {
            object, _ in
            DispatchQueue.main.async {
                self.progressOverlay.progressIndicator.doubleValue = object.fractionCompleted
            }
        }

        apiClient.fetchComments(of: story) { [weak self] commentsResults in
            guard let `self` = self else { return }

            let comments: [Comment] = commentsResults.flatMap {
                switch $0 {
                case let .success(comment): return comment
                case .failure:
                    return nil // TODO: Display (non-user facing) error
                }
            }

            self.progressObservation = nil

            self.commentsDataSource = comments
            self.commentsOutlineView.expandItem(nil, expandChildren: true)
            self.commentsOutlineView.scrollRowToVisible(0)

            // Enqueue the animations on the main thread, to give the time to the progress
            // indicator to update to its maxValue.
            DispatchQueue.main.async {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.completionHandler = {
                    self.commentsScrollView.animator().isHidden = false
                }
                self.progressOverlay.animator().isHidden = true
                NSAnimationContext.endGrouping()
            }
        }
    }
}

// MARK: - Selectors
private extension Selector {
    static let toggleCommentReplies = #selector(CommentsViewController.toggleCommentReplies(_:))
    static let scrollToParentComment = #selector(CommentsViewController.goToParentComment(_:))
}

// MARK: - NetworkingAware
extension CommentsViewController: NetworkingAware {}

// MARK: - NSOutlineView Data Source
extension CommentsViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard
            item != nil,
            let comment = item as? Comment,
            let kids = comment.kids
        else {
            return commentsDataSource.count
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

    func outlineView(_: NSOutlineView, objectValueFor _: NSTableColumn?, byItem item: Any?) -> Any? {
        guard let comment = item as? Comment else { return nil }
        return comment
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
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard
            let comment = item as? Comment,
            let dummyCellView = prototypeCellView
        else {
            return outlineView.rowHeight
        }

        let cellLevel = CGFloat(outlineView.level(forItem: comment)),
            availableWidth = outlineView.bounds.width - (outlineView.indentationPerLevel * cellLevel)

        dummyCellView.bounds.size = NSSize(width: availableWidth, height: 0)
        dummyCellView.objectValue = comment
        dummyCellView.layoutSubtreeIfNeeded()

        return dummyCellView.fittingSize.height
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        let comment = item as? Comment,
            cellView = outlineView.makeView(withIdentifier: .commentCell, owner: self) as? CommentCellView

        cellView?.objectValue = comment
        cellView?.isExpandable = outlineView.isExpandable(comment)
        cellView?.isExpanded = (cellView?.isExpandable ?? false) && outlineView.isItemExpanded(comment)
        cellView?.opBadgeView.isHidden = comment?.by != selectedStory?.by

        let repliesCount = commentsOutlineView.numberOfChildren(ofItem: comment)
        cellView?.repliesTextField.stringValue = "\(repliesCount) " + (repliesCount > 1 ? "replies" : "reply") + " hidden"
        cellView?.replyArrowTextField.isHidden = commentsOutlineView.parent(forItem: comment) == nil

        return cellView
    }

    func outlineViewColumnDidResize(_: Notification) {
        let wholeRowsIndexes: IndexSet = IndexSet(integersIn:0..<commentsOutlineView.numberOfRows)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0
            commentsOutlineView.noteHeightOfRows(
                withIndexesChanged: wholeRowsIndexes
            )
        })
    }
}

