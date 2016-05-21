//
//  MasterViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoriesViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet weak var storiesTableView: NSTableView!
    @IBOutlet weak var storiesProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var storiesProgressLabel: NSTextField!
    @IBOutlet weak var storiesProgressOverlay: NSStackView!
    @IBOutlet weak var storiesCountPopUpButton: NSPopUpButton!
    @IBOutlet weak var sidebarButton: NSButton!

    // MARK: Properties
    private let API = APIClient.sharedInstance
    private var selectedStoriesCategory: HackerNewsAPI = .NewStories
    private var selectedStoriesCount = 10
    private var stories = [Story]()
    private var previouslySelectedStory: Story?
    private dynamic var overallProgress: NSProgress?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        sidebarButton.toolTip = "Toggle Sidebar"
        storiesCountPopUpButton.toolTip = "Number of stories to display"
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(updateStoriesCategory(_:)),
            name: "NewStoriesCategorySelectedNotification", object: nil
        )

        addObserver(self, forKeyPath: "overallProgress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    override func viewDidAppear() {
        updateStories(selectedStoriesCategory, storiesCount: selectedStoriesCount)
    }

    // MARK: Methods
    func updateStoriesCategory(notification: NSNotification) {
        guard let selectedCategory = notification.userInfo?["selectedCategory"] as? String else {
            return
        }

        switch selectedCategory {
        case "Top": selectedStoriesCategory = .TopStories
        case "New": selectedStoriesCategory = .NewStories
        case "Ask": selectedStoriesCategory = .AskStories
        case "Jobs": selectedStoriesCategory = .JobStories
        default: return
        }

        updateStories(selectedStoriesCategory, storiesCount: selectedStoriesCount)
    }

    @IBAction private func userDidChangeStoriesCount(sender: NSPopUpButton) {
        guard let storiesCountItem = storiesCountPopUpButton.selectedItem,
            storiesCount = Int(storiesCountItem.title) else {
                return
        }

        selectedStoriesCount = storiesCount

        updateStories(selectedStoriesCategory, storiesCount: storiesCount)
    }

    @IBAction private func userDidClickSidebarButton(sender: NSButton) {
        guard let splitViewController = parentViewController as? NSSplitViewController else {
            return
        }

        splitViewController.toggleSidebar(self)
    }

    @IBAction private func userDidSelectStory(sender: NSTableView) {
        guard let splitViewController = parentViewController as? NSSplitViewController,
            commentsViewController = splitViewController.splitViewItems[2].viewController as? CommentsViewController else {
                return
        }

        let selectedStory = stories[storiesTableView.selectedRow]

        if previouslySelectedStory?.id == selectedStory.id {
            return
        }

        commentsViewController.updateComments(stories[storiesTableView.selectedRow])

        previouslySelectedStory = stories[storiesTableView.selectedRow]
    }

    func updateStories(storiesType: HackerNewsAPI, storiesCount: Int) {
        NSAnimationContext.runAnimationGroup({ context in
            context.allowsImplicitAnimation = true
            self.storiesTableView.hidden = true
            self.storiesProgressOverlay.hidden = false
            }, completionHandler: nil)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.overallProgress = NSProgress(totalUnitCount: Int64(storiesCount))
            self.overallProgress?.becomeCurrentWithPendingUnitCount(Int64(storiesCount))

            self.API.fetchStories(storiesCount, source: storiesType) { stories in
                self.stories = stories
                self.storiesTableView.reloadData()
                self.storiesTableView.scrollRowToVisible(0)

                NSAnimationContext.runAnimationGroup({ context in
                    context.allowsImplicitAnimation = true
                    self.storiesTableView.hidden = false
                    self.storiesProgressOverlay.hidden = true
                    }, completionHandler: nil)
            }

            self.overallProgress?.resignCurrent()
        }
    }

    private func configureCell(cellView: StoryTableCellView, row: Int) -> StoryTableCellView {
        let story = stories[row]

        cellView.titleTextField.stringValue = story.title

        if let URL = story.url, shortURL = URL.shortURL() {
            cellView.URLButton.title = shortURL
            cellView.URLButton.toolTip = URL.absoluteString
        } else {
            cellView.URLButton.hidden = true
        }

        let comments = String(format: story.descendants > 1 ? "%d comments" : story.descendants == 0 ? "no comments" : "%d comment", story.descendants)

        cellView.subtitleTextField.stringValue = "by \(story.by), \(story.time.timeAgo()) — \(comments)"

        return cellView
    }

    private func handleCommentsUpdate(notification: NSNotification) {
        if let completed = notification.userInfo?["completed"] as? Bool {
            dispatch_async(dispatch_get_main_queue()) {
                self.storiesTableView.enabled = completed
            }
        }
    }

    // MARK: Progress KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "overallProgress.fractionCompleted" {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Double {
                dispatch_async(dispatch_get_main_queue()) {
                    self.storiesProgressIndicator.doubleValue = newValue
                }
            }
        }
    }
}

// MARK: TableView Source
extension StoriesViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return stories.count
    }
}

// MARK: TableView Delegate
extension StoriesViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // FIXME:
        // We avoid creating & reusing a cell for row height calculating purposes when
        // doing things this way, but we do have reproduce the cell's title formatting
        // that is already defined in the corresponding XIB... Not very flexible
        let formattedTitle = NSAttributedString(
            string: stories[row].title, attributes:
                [NSFontAttributeName: NSFont.systemFontOfSize(
                    NSFont.systemFontSize(), weight: NSFontWeightMedium
                    )
            ]
        ),
            contentHeightWithoutTitle: CGFloat = 56.0,
            titleWidth = tableView.frame.width - 20.0,
            titleHeight = formattedTitle.boundingRectWithSize(
                NSSize(width: titleWidth, height: CGFloat.max),
                options: [.UsesLineFragmentOrigin, .UsesFontLeading]
        ).height

        return max(tableView.rowHeight, titleHeight + contentHeightWithoutTitle)
    }

    func tableViewColumnDidResize(notification: NSNotification) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0
            self.storiesTableView.noteHeightOfRowsWithIndexesChanged(
                NSIndexSet(indexesInRange: NSMakeRange(0, self.storiesTableView.numberOfRows))
            )
            }, completionHandler: nil)
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        guard let column = tableColumn where column.identifier == "StoryColumn" else {
            return nil
        }

        return self.stories[row]
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeViewWithIdentifier("StoryColumn", owner: self) as? StoryTableCellView else {
            return nil
        }

        configureCell(cellView, row: row)

        return cellView
    }
}
