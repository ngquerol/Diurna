//
//  CommentsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 30/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CommentsViewController : NSViewController {

    // MARK: Outlets
    @IBOutlet weak var commentsStoryTitle: NSTextField!
    @IBOutlet weak var commentsHeader: NSView!
    @IBOutlet weak var commentsPlaceholderLabel: NSTextField!
    @IBOutlet weak var commentsOutlineView: NSOutlineView!
    @IBOutlet weak var commentsProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var commentsProgressOverlay: NSStackView!

    // MARK: Properties
    private let API = APIClient()
    private var op = String()
    private var comments = [Comment]() {
        didSet {
            self.commentsOutlineView.reloadData()
            self.commentsOutlineView.scrollRowToVisible(0)
            self.comments.forEach { commentsOutlineView.expandItem($0, expandChildren: true) }
        }
    }
    private dynamic var overallProgress: NSProgress?

    // MARK: View lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        addObserver(self, forKeyPath: "overallProgress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    // MARK: Methods
    func updateComments(story: Story) {
        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.commentsOutlineView.animator().hidden = true
            self.commentsStoryTitle.animator().hidden = true
            self.commentsStoryTitle.stringValue = story.title
            self.commentsStoryTitle.animator().hidden = false
            NSAnimationContext.endGrouping()
        }

        if story.descendants == 0 {
            NSAnimationContext.beginGrouping()
            self.commentsPlaceholderLabel.animator().hidden = false
            self.commentsPlaceholderLabel.stringValue = "No comments yet."
            NSAnimationContext.endGrouping()
            return
        }

        op = story.by

        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.commentsProgressOverlay.animator().hidden = false
            self.commentsPlaceholderLabel.animator().hidden = true
            self.commentsOutlineView.animator().hidden = true
            NSAnimationContext.endGrouping()
        }

        self.overallProgress = NSProgress(totalUnitCount: Int64(story.descendants))
        self.overallProgress?.becomeCurrentWithPendingUnitCount(Int64(story.descendants))

        API.fetchComments(story) { comments in
            self.comments = comments

            dispatch_async(dispatch_get_main_queue()) {
                NSAnimationContext.beginGrouping()
                self.commentsOutlineView.animator().hidden = false
                self.commentsProgressOverlay.animator().hidden = true
                NSAnimationContext.endGrouping()
            }
        }

        self.overallProgress?.resignCurrent()
    }

    private func configureCell(cellView: CommentTableCellView, comment: Comment) -> CommentTableCellView {
        cellView.time.objectValue = comment.time

        if comment.deleted {
            cellView.author.title = "[deleted]"
            cellView.author.enabled = false
            cellView.text.stringValue = ""
            cellView.op.hidden = true
        } else {
            cellView.author.attributedTitle = NSAttributedString(string: comment.by, attributes: [NSForegroundColorAttributeName: uniqueColorFromString(comment.by)])
            cellView.op.hidden = (comment.by != op)
            cellView.text.attributedStringValue = MarkupParser(input: comment.text).toAttributedString()
        }

        return cellView
    }

// TODO: should be empirically tweaked to give legible results, and optionally made a String extension
    private func uniqueColorFromString(string: String) -> NSColor {
        srandom(UInt32(truncatingBitPattern: string.hashValue)) // careful about that overflow
        let hue = CGFloat(Double(random() % 256) / 256.0),
            saturation = CGFloat(Double(random() % 128) / 256.0 + 0.8),
            brightness = CGFloat(Double(random() % 128) / 256.0 + 0.8)

        return NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }

// MARK: Progress KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
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
        guard let comment = item as? Comment,
            var cellView = commentsOutlineView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentTableCellView else {
                return outlineView.rowHeight
        }

        let cellLevel = outlineView.levelForItem(item),
            textWidth = (outlineView.frame.width - 40.0) - (CGFloat(cellLevel) * outlineView.indentationPerLevel)

        cellView = configureCell(cellView, comment: comment)

        let textHeight = cellView.text.attributedStringValue.boundingRectWithSize(NSSize(width: textWidth, height: CGFloat.max), options: [.UsesFontLeading, .UsesLineFragmentOrigin]).height

        return max(outlineView.rowHeight, textHeight + 45.0)
    }

    func outlineViewColumnDidResize(notification: NSNotification) {
        commentsOutlineView.noteHeightOfRowsWithIndexesChanged(
            NSIndexSet(indexesInRange: NSMakeRange(0, commentsOutlineView.numberOfRows))
        )
    }
}