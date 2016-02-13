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

        guard previouslySelectedStory?.id != selectedStory.id else {
            return
        }

        selectedStory.read = true

        dispatch_async(dispatch_get_main_queue()) {
            self.storiesTableView.reloadData()
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

        storiesCountPopUp.removeAllItems()
        storiesCountPopUp.addItemsWithTitles(storiesCounts.map({ $0.0 }))

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

    // MARK: API interaction
    func updateStories() {
        let selectedCount = storiesCountPopUp.selectedItem?.title,
            selectedTypeSegment = storiesTypeSegmentedControl.selectedSegment,
            selectedType = storiesTypeSegmentedControl.labelForSegment(selectedTypeSegment)!

        dispatch_async(dispatch_get_main_queue()) {
            NSAnimationContext.beginGrouping()
            self.storiesTableView.animator().hidden = true
            self.storiesTypeSegmentedControl.enabled = false
            self.storiesCountPopUp.enabled = false
            self.storiesProgressIndicator.animator().hidden = false
            NSAnimationContext.endGrouping()
        }

        API.fetchStories(storiesCounts[selectedCount!]!, source: storiesTypes[selectedType]!) { stories in
            self.stories = stories

            dispatch_async(dispatch_get_main_queue()) {
                NSAnimationContext.beginGrouping()
                self.storiesTableView.animator().hidden = false
                self.storiesTypeSegmentedControl.enabled = true
                self.storiesCountPopUp.enabled = true
                self.storiesProgressIndicator.animator().hidden = true
                NSAnimationContext.endGrouping()
            }
        }
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

    // MARK: Methods
    private func formatURL(url: NSURL) -> String? {
        let undesirablePrefixesPattern = "^(www[0-9]*)\\."

        guard let host = url.host else {
            return nil
        }

        if let match = host.rangeOfString(undesirablePrefixesPattern, options: .RegularExpressionSearch) {
            return host.substringFromIndex(match.endIndex)
        }

        return host
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

// MARK: TableView Source & Delegate
extension StoriesViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return stories.count
    }
}

extension StoriesViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(notification: NSNotification) {
        let rowView = storiesTableView.rowViewAtRow(storiesTableView.selectedRow, makeIfNecessary: false)
        rowView?.selectionHighlightStyle = .Regular
        rowView?.emphasized = false
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as? StoryTableCellView else {
            return nil
        }

        let story = stories[row]

        cellView.readStatus.hidden = story.read
        cellView.title.stringValue = story.title
        cellView.by.stringValue = story.by

        if let url = story.url {
            cellView.URL.title = formatURL(url) ?? ""
            cellView.URL.target = self
            cellView.URL.action = "visitURL:"
        }

        cellView.comments.stringValue = String(format: story.comments.count > 1 ? "%d comments" : story.comments.count == 0 ? "no comments" : "%d comment", story.comments.count)

        cellView.time.objectValue = story.time

        return cellView
    }
}
