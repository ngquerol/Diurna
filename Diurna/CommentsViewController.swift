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
    @IBOutlet weak var commentsTableView: NSTableView!
    @IBOutlet weak var commentsProgressIndicator: NSProgressIndicator!

    // MARK: Properties
    private let API = APIClient()
    private var op = String()
    private var comments = [Comment]() {
        didSet {
            commentsTableView.reloadData()
            commentsTableView.scrollRowToVisible(0)
        }
    }

    // MARK: View lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        API.addObserver(self, forKeyPath: "progress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    // MARK: Methods
    func updateComments(story: Story) {
        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.commentsTableView.animator().hidden = true
            self.commentsStoryTitle.animator().hidden = true
            self.commentsStoryTitle.stringValue = story.title
            self.commentsStoryTitle.animator().hidden = false
            NSAnimationContext.endGrouping()
        }

        if story.comments.count == 0 {
            NSAnimationContext.beginGrouping()
            self.commentsPlaceholderLabel.animator().hidden = false
            self.commentsPlaceholderLabel.stringValue = "No comments yet."
            NSAnimationContext.endGrouping()
            return
        }

        op = story.by

        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.commentsProgressIndicator.animator().hidden = false
            self.commentsProgressIndicator.doubleValue = 0.0
            self.commentsPlaceholderLabel.animator().hidden = true
            self.commentsTableView.animator().hidden = true
            NSAnimationContext.endGrouping()
        }

        API.fetchComments(story.comments) { comments in
            self.comments = comments

            dispatch_async(dispatch_get_main_queue()) {
                NSAnimationContext.beginGrouping()
                self.commentsTableView.animator().hidden = false
                self.commentsProgressIndicator.animator().hidden = true
                NSAnimationContext.endGrouping()
            }
        }
    }

    private func configureCell(cell: CommentTableCellView, row: Int) -> CommentTableCellView? {
        let comment = comments[row]

        cell.time.objectValue = comment.time

        if comment.deleted {
            cell.author.title = "[deleted]"
            cell.author.enabled = false
            cell.text.stringValue = ""
            cell.op.hidden = true
        } else {
            cell.author.attributedTitle = NSAttributedString(string: comment.by, attributes: [NSForegroundColorAttributeName: uniqueColorFromString(comment.by)])
            cell.op.hidden = (comment.by != op)
            cell.text.attributedStringValue = NSAttributedString(htmlString: comment.text)
        }

        return cell
    }

// TODO: should be empirically tweaked to give legible results, and optionally made a String extension
    private func uniqueColorFromString(string: String) -> NSColor {
        srandom(UInt32(truncatingBitPattern: string.hash)) // careful about that overflow
        let hue = CGFloat(Double(random() % 256) / 256.0),
        saturation = CGFloat(Double(random() % 128) / 256.0 + 0.5),
        brightness = CGFloat(Double(random() % 128) / 256.0 + 0.5)

        return NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }

// MARK: Progress KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "progress.fractionCompleted" {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Double {
                dispatch_async(dispatch_get_main_queue()) {
                    self.commentsProgressIndicator.doubleValue = newValue
                }
            }
        }
    }
}

// MARK: TableView Source
extension CommentsViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return comments.count
    }
}

// MARK: TableView Delegate
extension CommentsViewController : NSTableViewDelegate {
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let defaultHeight: CGFloat = 61.0

        guard var cellView = commentsTableView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentTableCellView else {
            return defaultHeight
        }

        cellView = configureCell(cellView, row: row)!
        return cellView.text.attributedStringValue.boundingRectWithSize(NSSize(width: tableView.bounds.width - 40.0, height: CGFloat.max), options: [.UsesFontLeading, .UsesLineFragmentOrigin]).height + 45.0
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = commentsTableView.makeViewWithIdentifier("CommentColumn", owner: self) as? CommentTableCellView else {
            return nil
        }

        return configureCell(cellView, row: row)
    }
}