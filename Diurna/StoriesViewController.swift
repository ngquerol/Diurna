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
    @IBOutlet weak var storiesProgressOverlay: NSStackView!

    @IBAction func storiesCountUpdated(sender: NSPopUpButton) {
        updateStories()
    }

    @IBAction func storiesTypeUpdated(sender: NSSegmentedControl) {
        updateStories()
    }

    @IBAction func userDidSelectStory(sender: NSTableView) {
        let splitViewController = parentViewController as! NSSplitViewController
        let commentsPane = splitViewController.splitViewItems[1]
        let commentsViewController = commentsPane.viewController as! CommentsViewController
        let selectedStory = stories[storiesTableView.selectedRow]

        if previouslySelectedStory?.id == selectedStory.id {
            return
        }

        commentsViewController.updateComments(stories[storiesTableView.selectedRow])

        previouslySelectedStory = stories[storiesTableView.selectedRow]
    }

    // MARK: Properties
    private let storiesCounts = [
        "10": 10,
        "20": 20,
        "50": 50,
    ]
    private let storiesTypes = [
        "Top": HackerNewsAPI.TopStories,
        "New": HackerNewsAPI.NewStories
    ]
    private let API = APIClient()
    private var stories = [Story]() {
        didSet {
            self.storiesTableView.reloadData()
            self.storiesTableView.scrollRowToVisible(0)
        }
    }
    private var previouslySelectedStory: Story?

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        storiesTableView.selectionHighlightStyle = .Regular

        storiesCountPopUp.removeAllItems()
        storiesCountPopUp.addItemsWithTitles(storiesCounts.map { $0.0})

        for (index, type) in storiesTypes.enumerate() {
            storiesTypeSegmentedControl.setLabel(type.0, forSegment: index)
        }
        storiesTypeSegmentedControl.selectSegmentWithTag(0)

        updateStories()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        API.addObserver(self, forKeyPath: "progress.fractionCompleted", options: [.New, .Initial], context: nil)
    }

    // MARK: Methods
    func updateStories() {
        let selectedCount = storiesCountPopUp.selectedItem?.title,
        selectedTypeSegment = storiesTypeSegmentedControl.selectedSegment,
        selectedType = storiesTypeSegmentedControl.labelForSegment(selectedTypeSegment)!

        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.storiesTableView.animator().hidden = true
            self.storiesTypeSegmentedControl.enabled = false
            self.storiesCountPopUp.enabled = false
            self.storiesProgressOverlay.animator().hidden = false
            NSAnimationContext.endGrouping()
        }

        API.fetchStories(storiesCounts[selectedCount!]!, source: storiesTypes[selectedType]!) { stories in
            self.stories = stories

            dispatch_async(dispatch_get_main_queue()) {
                NSAnimationContext.beginGrouping()
                self.storiesTableView.animator().hidden = false
                self.storiesTypeSegmentedControl.enabled = true
                self.storiesCountPopUp.enabled = true
                self.storiesProgressOverlay.animator().hidden = true
                NSAnimationContext.endGrouping()
            }
        }
    }

    private func configureCell(cellView: StoryTableCellView, row: Int) -> StoryTableCellView {
        let story = stories[row]

        cellView.title.stringValue = story.title
        cellView.by.stringValue = story.by

        if let url = story.url {
            cellView.URL.title = url.shortURL() ?? ""
            cellView.URL.target = self
            cellView.URL.action = "visitURL:"
        } else {
            cellView.URL.hidden = true
        }

        cellView.comments.stringValue = String(format: story.comments.count > 1 ? "%d comments" : story.comments.count == 0 ? "no comments" : "%d comment", story.comments.count)

        cellView.time.objectValue = story.time

        return cellView
    }

    // MARK: Actions
    func visitURL(sender: AnyObject) {
        guard let urlButton = sender as? NSView else {
            return
        }

        let row = storiesTableView.rowForView(urlButton)

        guard row != -1, let url = stories[row].url else {
            return
        }

        NSWorkspace.sharedWorkspace().openURL(url)
    }

    // MARK: Progress KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "progress.fractionCompleted" {
            if let newValue = change?[NSKeyValueChangeNewKey] {
                dispatch_async(dispatch_get_main_queue()) {
                    self.storiesProgressIndicator.doubleValue = newValue as! Double
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
        let calculatedHeight = cellView.title.attributedStringValue.boundingRectWithSize(NSSize(width: tableView.bounds.width - 20.0, height: CGFloat.max), options: [.UsesFontLeading, .UsesLineFragmentOrigin]).height + 50.0

        return max(tableView.rowHeight, calculatedHeight)
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as? StoryTableCellView else {
            return nil
        }

        configureCell(cellView, row: row)

        return cellView
    }
}
