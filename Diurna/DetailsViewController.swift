//
//  CommentsViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 22/06/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class DetailsViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var detailsPlaceholderLabel: NSTextField!
    @IBOutlet weak var storyDetailsStackView: NSStackView!
    @IBOutlet weak var storyTitleTextField: ClickableTextField! {
        didSet {
            storyTitleTextField.isHidden = true
        }
    }
    @IBOutlet weak var storyDetailTextField: NSTextField! {
        didSet {
            storyDetailTextField.isHidden = true
        }
    }
    @IBOutlet weak var storyDetailPlaceholder: NSTextField! {
        didSet {
            storyDetailPlaceholder.isHidden = true
        }
    }
    @IBOutlet weak var commentsScrollView: NSScrollView!
    @IBOutlet weak var commentsOutlineView: NSOutlineView!
    @IBOutlet weak var commentsProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var commentsProgressLabel: NSTextField!
    @IBOutlet weak var commentsProgressStackView: NSStackView! {
        didSet {
            commentsProgressStackView.isHidden = true
        }
    }
    @IBOutlet weak var commentsPlaceholder: NSTextField! {
        didSet {
            commentsPlaceholder.isHidden = true
        }
    }
    @IBOutlet weak var storyTitleLeadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var storyTitleTrailingSpaceConstraint: NSLayoutConstraint!

    // MARK: Properties
    fileprivate let API: APIClient = MockAPIClient.sharedInstance
    fileprivate let dummyCellView = CommentCellView()
    fileprivate dynamic var overallProgress: Progress?
    fileprivate var comments = [Comment]() {
        didSet {
            commentsOutlineView.reloadData()
        }
    }
    fileprivate var selectedStory: Story?
    fileprivate var storyDetailsShown: Bool = false

    // MARK: (De)initializer(s)
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View lifecycle
    override func viewWillLayout() {
        super.viewWillLayout()

        storyTitleTextField.preferredMaxLayoutWidth = contentView.bounds.width - (storyTitleLeadingSpaceConstraint.constant + storyTitleTrailingSpaceConstraint.constant)
        storyDetailTextField.preferredMaxLayoutWidth = contentView.bounds.width - (storyTitleLeadingSpaceConstraint.constant + storyTitleTrailingSpaceConstraint.constant)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .updateDetails,
            name: .storySelectionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: .toggleCommentReplies,
            name: .toggleCommentRepliesNotification,
            object: nil
        )

        addObserver(
            self,
            forKeyPath: #keyPath(overallProgress.fractionCompleted),
            options: [.new],
            context: nil
        )
    }

    // MARK: Methods
    @IBAction func toggleStoryText(_ sender: ClickableTextField) {
        guard sender == storyTitleTextField else {
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().allowsImplicitAnimation = true
        storyDetailTextField.isHidden = storyDetailsShown || selectedStory?.text == nil
        storyDetailPlaceholder.isHidden = storyDetailsShown || selectedStory?.text != nil
        NSAnimationContext.endGrouping()

        storyDetailsShown = !storyDetailsShown
    }

    func toggleCommentReplies(_ notification: Notification) {
        guard notification.name == .toggleCommentRepliesNotification,
            let cellView = notification.object as? CommentCellView,
            let comment = cellView.objectValue as? Comment,
            let toggleReplies = notification.userInfo?["toggleChildren"] as? Bool else {
                return
        }

        if commentsOutlineView.isItemExpanded(comment) {
            cellView.isCollapsed = true
            cellView.repliesTextField.animator().alphaValue = 1.0
            commentsOutlineView.animator().collapseItem(comment, collapseChildren: toggleReplies)
        } else {
            cellView.isCollapsed = false
            cellView.repliesTextField.animator().alphaValue = 0.0
            commentsOutlineView.animator().expandItem(comment, expandChildren: toggleReplies)
        }
    }

    func updateDetails(_ notification: Notification) {
        guard notification.name == .storySelectionNotification,
            let story = notification.userInfo?["story"] as? Story else {
                return
        }

        selectedStory = story

        updateStoryDetails(story)
        updateComments(story)
    }

    fileprivate func updateStoryDetails(_ story: Story) {
        storyTitleTextField.stringValue = story.title

        storyTitleTextField.animator().isHidden = true
        storyDetailTextField.attributedStringValue = story.text?.parseMarkup() ?? NSAttributedString()
        storyTitleTextField.animator().isHidden = false
    }

    fileprivate func updateComments(_ story: Story) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().allowsImplicitAnimation = true
        commentsScrollView.isHidden = true
        detailsPlaceholderLabel.isHidden = true
        NSAnimationContext.endGrouping()

        guard story.descendants != 0 else {
            commentsPlaceholder.animator().isHidden = false
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().allowsImplicitAnimation = true
        commentsProgressStackView.isHidden = false
        commentsPlaceholder.isHidden = true
        NSAnimationContext.endGrouping()

        DispatchQueue.global(qos: .userInitiated).async {
            self.overallProgress = Progress(totalUnitCount: Int64(story.descendants))
            self.overallProgress?.becomeCurrent(withPendingUnitCount: Int64(story.descendants))

            self.API.fetchComments(of: story) { comments in
                self.comments = comments
                self.commentsOutlineView.expandItem(nil, expandChildren: false)
                self.commentsOutlineView.scrollRowToVisible(0)

                // Enqueue the animations on the main thread, to give the time to the progress
                // indicator to update to its maxValue.
                DispatchQueue.main.async {
                    NSAnimationContext.beginGrouping()
                    self.commentsProgressStackView.animator().isHidden = true
                    NSAnimationContext.current().completionHandler = {
                        self.commentsScrollView.animator().isHidden = false
                    }
                    NSAnimationContext.endGrouping()
                }
            }

            self.overallProgress?.resignCurrent()
        }
    }

    // MARK: Key-Value Observing
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(overallProgress.fractionCompleted),
            let newValue = change?[.newKey] as? Double else {
                return
        }

        DispatchQueue.main.async {
            self.commentsProgressIndicator.doubleValue = newValue
        }
    }
}

// MARK: - Selectors
private extension Selector {
    static let updateDetails = #selector(DetailsViewController.updateDetails(_:))
    static let toggleCommentReplies = #selector(DetailsViewController.toggleCommentReplies(_:))
}

// MARK: - NSOutlineView Data Source
extension DetailsViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let comment = item as? Comment else { return comments.count }
        return comment.kids.count
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable: Any) -> Bool {
        guard let comment = isItemExpandable as? Comment else { return false }
        return !comment.kids.isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        guard let comment = item as? Comment else { return nil }
        return comment
    }

    func outlineView(_: NSOutlineView, child: Int, ofItem: Any?) -> Any {
        guard let comment = ofItem as? Comment else { return comments[child] }
        return comment.kids[child]
    }
}

// MARK: - NSOutlineView Delegate
extension DetailsViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let comment = item as? Comment else {
            return outlineView.rowHeight
        }

        let availableWidth = outlineView.frame.width - outlineView.indentationPerLevel * CGFloat(outlineView.level(forItem: comment))

        dummyCellView.configureFor(comment, story: selectedStory)

        return dummyCellView.heightForWidth(availableWidth)
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let comment = item as? Comment,
            let cellView = outlineView.make(withIdentifier: CommentCellView.reuseIdentifier, owner: self) as? CommentCellView else {
                let cellView = CommentCellView()
                return cellView
        }

        cellView.configureFor(comment, story: selectedStory)

        let repliesCount = commentsOutlineView.numberOfChildren(ofItem: comment)
        cellView.repliesTextField.stringValue = (repliesCount > 1 ? "\(repliesCount) replies" : "one reply") + " hidden"
        cellView.repliesStackView.isHidden = repliesCount == 0

        return cellView
    }

    func outlineViewColumnDidResize(_ notification: Notification) {
        guard notification.name == Notification.Name.NSOutlineViewColumnDidResize else { return }

        let visibleRowsRange = commentsOutlineView.rows(in: commentsOutlineView.visibleRect)
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0
        commentsOutlineView.noteHeightOfRows(
            withIndexesChanged: IndexSet(integersIn: visibleRowsRange.toRange()!)
        )
        NSAnimationContext.endGrouping()
    }
}
