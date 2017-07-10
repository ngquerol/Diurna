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
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var storyDetailsStackView: NSStackView! {
        didSet {
            storyDetailsStackView.isHidden = true
        }
    }

    @IBOutlet weak var storyTitleTextField: NSTextField! {
        didSet {
            storyTitleTextField.backgroundColor = Themes.current.backgroundColor
            storyTitleTextField.textColor = Themes.current.normalTextColor
        }
    }

    @IBOutlet weak var storyDetailsTextField: NSTextField! {
        didSet {
            storyDetailsTextField.isHidden = true
        }
    }

    @IBOutlet var storyTitleCenterConstraint: NSLayoutConstraint! {
        didSet {
            storyTitleCenterConstraint.isActive = false
        }
    }

    @IBOutlet var storyDetailsCenterConstraint: NSLayoutConstraint! {
        didSet {
            storyDetailsCenterConstraint.isActive = false
        }
    }

    @IBOutlet var storyTitleWidthConstraint: NSLayoutConstraint! {
        didSet {
            storyTitleWidthConstraint.isActive = false
        }
    }

    @IBOutlet var storyDetailsWidthConstraint: NSLayoutConstraint! {
        didSet {
            storyDetailsWidthConstraint.isActive = false
        }
    }

    @IBOutlet weak var commentsScrollView: NSScrollView! {
        didSet {
            commentsScrollView.isHidden = true
            commentsScrollView.backgroundColor = Themes.current.backgroundColor
        }
    }

    @IBOutlet weak var commentsOutlineView: NSOutlineView! {
        didSet {
            commentsOutlineView.backgroundColor = Themes.current.backgroundColor
        }
    }

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

    // MARK: Properties
    fileprivate var commentsDataSource: [Comment] = [] {
        didSet {
            commentsOutlineView.reloadData()
        }
    }

    fileprivate var selectedStory: Story?

    private let API: HackerNewsAPIClient = FirebaseAPIClient.sharedInstance

    private lazy var rowHeightCache: NSCache<Comment, NSNumber> = {
        let cache: NSCache<Comment, NSNumber> = NSCache()
        cache.countLimit = 500
        return cache
    }()

    private var progressObservation: NSKeyValueObservation?

    // MARK: (De)initializer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View Lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .updateViews,
            name: .storySelectionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: .toggleCommentReplies,
            name: .toggleCommentRepliesNotification,
            object: nil
        )
    }

    override func viewWillLayout() {
        super.viewWillLayout()

        let widthInsets = storyDetailsStackView.edgeInsets.left + storyDetailsStackView.edgeInsets.right,
            availableWidth = storyDetailsStackView.frame.width - widthInsets

        storyTitleTextField.preferredMaxLayoutWidth = availableWidth
        storyDetailsTextField.preferredMaxLayoutWidth = availableWidth
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

    @objc func updateViews(_ notification: Notification) {
        guard notification.name == .storySelectionNotification,
            let story = notification.userInfo?["story"] as? Story else {
            return
        }

        selectedStory = story

        updateDetails(from: story)
        updateComments(from: story)
    }

    private func updateDetails(from story: Story) {
        storyTitleTextField.stringValue = story.title
        storyTitleTextField.toolTip = story.title
        storyDetailsTextField.attributedStringValue = story.text?.parseMarkup() ?? NSAttributedString()

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        storyDetailsStackView.isHidden = false
        storyDetailsTextField.isHidden = story.text == nil
        NSAnimationContext.endGrouping()
    }

    private func updateComments(from story: Story) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        commentsScrollView.isHidden = true
        NSAnimationContext.endGrouping()

        guard story.descendants != 0 else {
            commentsPlaceholder.animator().isHidden = false
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        commentsProgressStackView.isHidden = false
        commentsPlaceholder.isHidden = true
        NSAnimationContext.endGrouping()

        let progress = Progress(totalUnitCount: Int64(story.descendants))

        progress.becomeCurrent(withPendingUnitCount: Int64(story.descendants))

        progressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) {
            object, _ in
                DispatchQueue.main.async {
                    self.commentsProgressIndicator.doubleValue = object.fractionCompleted
                }
            }

        API.fetchComments(of: story) { [weak self] commentsResults in
            guard let `self` = self else { return }

            let comments: [Comment] = commentsResults.flatMap {
                switch $0 {
                case .success(let comment): return comment
                case .failure(let error):
                    NSLog("Failed to fetch comment: %@", error.localizedDescription)
                    return nil
                }
            }

            self.commentsDataSource = comments
            self.commentsOutlineView.expandItem(nil, expandChildren: true)
            self.commentsOutlineView.scrollRowToVisible(0)

            // Enqueue the animations on the main thread, to give the time to the progress
            // indicator to update to its maxValue.
            DispatchQueue.main.async {
                NSAnimationContext.beginGrouping()
                self.commentsProgressStackView.animator().isHidden = true
                NSAnimationContext.current.completionHandler = {
                    self.commentsScrollView.animator().isHidden = false
                }
                NSAnimationContext.endGrouping()
            }

            progress.resignCurrent()
        }
    }
}

// MARK: - Selectors
private extension Selector {
    static let updateViews = #selector(CommentsViewController.updateViews(_:))
    static let toggleCommentReplies = #selector(CommentsViewController.toggleCommentReplies(_:))
}

// MARK: - NSOutlineView Data Source
extension CommentsViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil, let comment = item as? Comment else { return commentsDataSource.count }
        return comment.kids.count
    }

    func outlineView(_: NSOutlineView, isItemExpandable: Any) -> Bool {
        guard let comment = isItemExpandable as? Comment else { return false }
        return !comment.kids.isEmpty
    }

    func outlineView(_: NSOutlineView, objectValueFor _: NSTableColumn?, byItem item: Any?) -> Any? {
        guard let comment = item as? Comment else { return nil }
        return comment
    }

    func outlineView(_: NSOutlineView, child: Int, ofItem: Any?) -> Any {
        guard let comment = ofItem as? Comment else { return commentsDataSource[child] }
        return comment.kids[child]
    }
}

// MARK: - NSOutlineView Delegate
extension CommentsViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let comment = item as? Comment else {
            return outlineView.rowHeight
        }

        if let cachedRowHeight = rowHeightCache.object(forKey: comment) {
            return CGFloat(cachedRowHeight.floatValue)
        }

        guard let cellView = outlineView.makeView(withIdentifier: CommentCellView.reuseIdentifier, owner: self) as? CommentCellView else {
            return outlineView.rowHeight
        }

        let cellLevel = CGFloat(outlineView.level(forItem: comment)),
            availableWidth = outlineView.frame.width - (outlineView.indentationPerLevel * cellLevel)

        cellView.configureFor(comment, story: selectedStory)

        let calculatedRowHeight = cellView.heightForWidth(availableWidth)

        rowHeightCache.setObject(NSNumber(value: Float(calculatedRowHeight)), forKey: comment)

        return calculatedRowHeight
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let comment = item as? Comment,
            let cellView = outlineView.makeView(withIdentifier: CommentCellView.reuseIdentifier, owner: self) as? CommentCellView else {
            return nil
        }

        cellView.configureFor(comment, story: selectedStory)

        if outlineView.isExpandable(comment) {
            let repliesCount = commentsOutlineView.numberOfChildren(ofItem: comment)

            cellView.repliesStackView.isHidden = false
            cellView.repliesTextField.stringValue = "\(repliesCount) " + (repliesCount > 1 ? "replies" : "reply") + " hidden"
            cellView.isExpanded = outlineView.isItemExpanded(comment)
        } else {
            cellView.repliesStackView.isHidden = true
        }

        return cellView
    }

    func outlineViewColumnDidResize(_ notification: Notification) {
        guard
            notification.name == NSTableView.columnDidResizeNotification,
            let visibleRowsRange = Range(commentsOutlineView.rows(in: commentsOutlineView.visibleRect))
        else {
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        commentsOutlineView.noteHeightOfRows(
            withIndexesChanged: IndexSet(integersIn: visibleRowsRange)
        )
        NSAnimationContext.endGrouping()
    }
}
