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
    @IBOutlet weak var storiesTypeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var storiesCountPopUp: NSPopUpButton!
    @IBOutlet weak var storiesProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var storiesProgressLabel: NSTextField!
    @IBOutlet weak var storiesProgressOverlay: NSStackView!

    // MARK: Properties
    private let storiesCounts = ["10": 10, "20": 20, "50": 50,]
    private let storiesTypes = ["Top": HackerNewsAPI.TopStories, "New": HackerNewsAPI.NewStories]
    private let API = APIClient.sharedInstance
    private var stories = [Story]()
    private var previouslySelectedStory: Story?
    private dynamic var overallProgress: NSProgress?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        storiesCountPopUp.removeAllItems()
        storiesCountPopUp.addItemsWithTitles(storiesCounts.map { $0.0 })

        for (index, type) in storiesTypes.enumerate() {
            storiesTypeSegmentedControl.setLabel(type.0, forSegment: index)
        }
        storiesTypeSegmentedControl.selectSegmentWithTag(0)

        updateStories()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        addObserver(self, forKeyPath: "overallProgress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    // MARK: Methods
    @IBAction private func storiesCountUpdated(sender: NSPopUpButton) {
        updateStories()
    }

    @IBAction private func storiesTypeUpdated(sender: NSSegmentedControl) {
        updateStories()
    }

    @IBAction private func userDidSelectStory(sender: NSTableView) {
        guard let splitViewController = parentViewController as? NSSplitViewController,
            commentsViewController = splitViewController.splitViewItems[1].viewController as? CommentsViewController else {
                return
        }

        let selectedStory = stories[storiesTableView.selectedRow]

        if previouslySelectedStory?.id == selectedStory.id {
            return
        }

        commentsViewController.updateComments(stories[storiesTableView.selectedRow])

        previouslySelectedStory = stories[storiesTableView.selectedRow]
    }

    private func updateStories() {
        guard let selectedCount = storiesCounts[(storiesCountPopUp.selectedItem?.title)!],
            selectedType = storiesTypes[storiesTypeSegmentedControl.labelForSegment(storiesTypeSegmentedControl.selectedSegment)!] else {
                return
        }

        NSAnimationContext.runAnimationGroup({ context in
            self.storiesTableView.animator().hidden = true
            self.storiesTypeSegmentedControl.enabled = false
            self.storiesCountPopUp.enabled = false
            self.storiesProgressOverlay.animator().hidden = false
            }, completionHandler: nil)

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.overallProgress = NSProgress(totalUnitCount: Int64(selectedCount))
            self.overallProgress?.becomeCurrentWithPendingUnitCount(Int64(selectedCount))

            self.API.fetchStories(selectedCount, source: selectedType) { stories in
                self.stories = stories

                dispatch_async(dispatch_get_main_queue()) {
                    self.storiesTableView.reloadData()
                    self.storiesTableView.scrollRowToVisible(0)

                    NSAnimationContext.runAnimationGroup({ context in
                        // context.duration = 1
                        self.storiesTableView.animator().hidden = false
                        self.storiesTypeSegmentedControl.animator().enabled = true
                        self.storiesCountPopUp.animator().enabled = true
                        self.storiesProgressOverlay.animator().hidden = true
                        }, completionHandler: nil)
                }
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
        guard var cellView = storiesTableView.makeViewWithIdentifier("StoryColumn", owner: self) as? StoryTableCellView else {
            return tableView.rowHeight
        }

        cellView = configureCell(cellView, row: row)

        let titleWidth = tableView.frame.width - 20.0,
            titleHeight = cellView.titleTextField.attributedStringValue.boundingRectWithSize(
                NSSize(width: titleWidth, height: CGFloat.max),
                options: .UsesLineFragmentOrigin
        ).height

        return max(tableView.rowHeight, titleHeight + 56.0)
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
