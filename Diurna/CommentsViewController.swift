//
//  CommentsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 30/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentsViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet weak var commentsStoryTitle: NSTextField!
    @IBOutlet weak var commentsHeader: NSView!
    @IBOutlet weak var commentsPlaceholderLabel: NSTextField!
    @IBOutlet weak var commentsOutlineView: NSOutlineView!
    @IBOutlet weak var commentsProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var commentsProgressLabel: NSTextField!
    @IBOutlet weak var commentsProgressOverlay: NSStackView!

    // MARK: Properties
    private let API = APIClient.sharedInstance
    private var selectedStory: Story?
    private var comments = [Comment]()
    private dynamic var overallProgress: NSProgress?

    // MARK: View lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(toggleCommentVisibility(_:)), name: "ToggleCommentVisibilityNotification", object: nil)
        addObserver(self, forKeyPath: "overallProgress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    // MARK: Methods
    func updateComments(story: Story) {
        NSAnimationContext.runAnimationGroup({ context in
            self.commentsOutlineView.animator().hidden = true
            self.commentsStoryTitle.animator().hidden = true
            self.commentsStoryTitle.stringValue = story.title
            self.commentsStoryTitle.animator().hidden = false
            }, completionHandler: nil)

        guard story.descendants != 0 else {
            NSAnimationContext.runAnimationGroup({ context in
                self.commentsPlaceholderLabel.animator().hidden = false
                self.commentsPlaceholderLabel.stringValue = "No comments yet."
                }, completionHandler: nil)
            return
        }

        self.selectedStory = story

        NSAnimationContext.runAnimationGroup({ context in
            self.commentsProgressOverlay.animator().hidden = false
            self.commentsPlaceholderLabel.animator().hidden = true
            self.commentsOutlineView.animator().hidden = true
            }, completionHandler: nil)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.overallProgress = NSProgress(totalUnitCount: Int64(story.descendants))
            self.overallProgress?.becomeCurrentWithPendingUnitCount(Int64(story.descendants))

            self.API.fetchComments(story) { comments in
                self.comments = comments
                self.commentsOutlineView.reloadData()
                self.commentsOutlineView.scrollRowToVisible(0)

                NSAnimationContext.runAnimationGroup({ context in
                    self.commentsOutlineView.animator().hidden = false
                    self.commentsProgressOverlay.animator().hidden = true
                    }, completionHandler: nil)
            }

            self.overallProgress?.resignCurrent()
        }
    }

    func toggleCommentVisibility(notification: NSNotification) {
        guard notification.name == "ToggleCommentVisibilityNotification",
            let toggledComment = notification.userInfo!["comment"] as? Comment else {
                return
        }

        let isCommentExpanded = commentsOutlineView.isItemExpanded(toggledComment)

        if isCommentExpanded {
            commentsOutlineView.animator().collapseItem(toggledComment, collapseChildren: true)
            commentsOutlineView.animator().scrollRowToVisible(commentsOutlineView.rowForItem(toggledComment))
        } else {
            commentsOutlineView.animator().expandItem(toggledComment, expandChildren: true)
            commentsOutlineView.animator().scrollRowToVisible(commentsOutlineView.rowForItem(toggledComment.kids[0]))
        }
    }

    private func configureCell(cellView: CommentTableCellView, comment: Comment) -> CommentTableCellView {
        cellView.timeTextField.stringValue = comment.time.timeAgo()

        if comment.deleted {
            cellView.wantsLayer = true
            cellView.layer?.opacity = 0.5
            cellView.textContainerView.wantsLayer = false
            cellView.authorButton.title = "[deleted]"
            cellView.authorButton.enabled = false
            cellView.textTextField.stringValue = ""
            cellView.opButton.hidden = true
            cellView.showRepliesButton.hidden = true
        } else {
            cellView.wantsLayer = false
            cellView.authorButton.title = comment.by
            cellView.opButton.hidden = (comment.by != selectedStory?.by)
            cellView.textTextField.attributedStringValue = comment.text
            cellView.showRepliesButton.hidden = (comment.parent != selectedStory?.id) || (comment.kids.count == 0)
        }

        return cellView
    }

// MARK: Progress KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "overallProgress.fractionCompleted" {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Double {
                dispatch_async(dispatch_get_main_queue()) {
                    self.commentsProgressIndicator.doubleValue = newValue
                }
            }
        }
    }
}

// MARK: NSOutlineView Data Source
extension CommentsViewController: NSOutlineViewDataSource {
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        guard let comment = item as? Comment else {
            return comments.count
        }

        return comment.kids.count
    }

    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        guard let comment = item as? Comment else {
            return false
        }

        return comment.kids.count > 0
    }

    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        guard let comment = item as? Comment where item != nil else {
            return comments[index]
        }

        return comment.kids[index]
    }

    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        guard let column = tableColumn where column.identifier == "CommentColumn",
            let comment = item as? Comment else {
                return nil
        }

        return comment
    }

    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        guard let comment = item as? Comment,
            cellView = outlineView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentTableCellView else {
                return nil
        }

        return configureCell(cellView, comment: comment)
    }
}

// MARK: NSOutlineView Delegate
extension CommentsViewController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        guard let comment = item as? Comment else {
            return outlineView.rowHeight
        }

        // FIXME:
        // performance is satisfactory as of now, but this could use the help of a row height cache
        let contentHeightWithoutText: CGFloat = 45.0,
            cellLevel = outlineView.levelForItem(item),
            textWidth = (outlineView.frame.width - 40) - (CGFloat(cellLevel) * outlineView.indentationPerLevel)

        let titleHeight = comment.text.boundingRectWithSize(
            NSSize(width: textWidth, height: CGFloat.max),
            options: [.UsesFontLeading, .UsesLineFragmentOrigin]
        ).height

        return titleHeight + contentHeightWithoutText
    }

    func outlineView(outlineView: NSOutlineView, rowViewForItem item: AnyObject) -> NSTableRowView? {
        let identifier = "CommentRowView"

        guard let rowView = outlineView.makeViewWithIdentifier(identifier, owner: nil) as? CommentTableRowView else {
            let rowView = CommentTableRowView()
            rowView.identifier = identifier
            return rowView
        }

        return rowView
    }

    func outlineViewColumnDidResize(notification: NSNotification) {
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0
                self.commentsOutlineView.noteHeightOfRowsWithIndexesChanged(
                    NSIndexSet(indexesInRange: NSMakeRange(0, self.commentsOutlineView.numberOfRows))
                )
            }, completionHandler: nil
        )
    }
}