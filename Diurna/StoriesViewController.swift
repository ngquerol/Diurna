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
    @IBOutlet weak var storiesToolbarView: NSView!
    @IBOutlet weak var storiesScrollView: NSScrollView!
    @IBOutlet weak var storiesTableView: NSTableView!
    @IBOutlet weak var storiesProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var storiesProgressLabel: NSTextField!
    @IBOutlet weak var storiesProgressOverlay: NSStackView!
    @IBOutlet weak var storiesCountPopUpButton: NSPopUpButton! {
        didSet {
            storiesCountPopUpButton.toolTip = "Number of stories to display"
        }
    }

    // MARK: Properties
    fileprivate let API: APIClient = MockAPIClient.sharedInstance
    fileprivate let dummyCellView = StoryCellView()
    fileprivate var selectedStoriesType = StoryType.new
    fileprivate var selectedStoriesCount = 10
    fileprivate var stories = [Story]() {
        didSet {
            stories.sort()
            storiesTableView.reloadData()
        }
    }
    fileprivate var selectedStory: Story?
    fileprivate dynamic var overallProgress: Progress?

    // MARK: (De)initializer(s)
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View lifecycle
    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .updateStoriesCategory,
            name: .newCategorySelectedNotification,
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
    func updateStoriesCategory(_ notification: Notification) {
        guard notification.name == .newCategorySelectedNotification,
            let categoryName = notification.userInfo?["selectedCategory"] as? String else {
                return
        }

        if let category = StoryType(rawValue: categoryName) {
            selectedStoriesType = category
            updateStories()
        } else {
            NSLog("%@: Unknown story type \"%@\"", className, categoryName)
        }
    }

    @IBAction func userDidSelectStory(_ sender: NSTableView) {
        guard selectedStory?.id != stories[storiesTableView.selectedRow].id else { return }

        selectedStory = stories[storiesTableView.selectedRow]

        NotificationCenter.default.post(
            name: .storySelectionNotification,
            object: self,
            userInfo: [
                "story": stories[storiesTableView.selectedRow]
            ]
        )
    }

    @IBAction fileprivate func storiesCountButtonValueChanged(_ sender: NSPopUpButton) {
        guard let storiesCountItem = storiesCountPopUpButton.selectedItem,
            let storiesCount = Int(storiesCountItem.title) else {
                return
        }

        selectedStoriesCount = storiesCount

        updateStories()
    }

    func updateStories() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().allowsImplicitAnimation = true
        storiesTableView.isHidden = true
        storiesProgressOverlay.isHidden = false
        NSAnimationContext.endGrouping()

        DispatchQueue.global(qos: .userInitiated).async {
            self.overallProgress = Progress(totalUnitCount: Int64(self.selectedStoriesCount))
            self.overallProgress?.becomeCurrent(withPendingUnitCount: Int64(self.selectedStoriesCount))

            self.API.fetchStories(of: self.selectedStoriesType, count: self.selectedStoriesCount) { stories in
                self.stories = stories
                self.storiesTableView.scrollRowToVisible(0)

                DispatchQueue.main.async {
                    NSAnimationContext.beginGrouping()
                    self.storiesProgressOverlay.animator().isHidden = true
                    NSAnimationContext.current().completionHandler = {
                        self.storiesTableView.animator().isHidden = false
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
            let newValue = change?[NSKeyValueChangeKey.newKey] as? Double else {
                return
        }

        DispatchQueue.main.async {
            self.storiesProgressIndicator.doubleValue = newValue
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let storySelectionNotification = Notification.Name("StorySelectionNotification")
}

// MARK: - Selectors
private extension Selector {
    static let updateStoriesCategory = #selector(StoriesViewController.updateStoriesCategory(_:))
}

// MARK: - NSTableView Data Source
extension StoriesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return stories.count
    }
}

// MARK: - NSTableView Delegate
extension StoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        dummyCellView.configureFor(stories[row])
        return dummyCellView.heightForWidth(tableView.frame.width)
    }

    func tableViewColumnDidResize(_ notification: Notification) {
        guard notification.name == Notification.Name.NSTableViewColumnDidResize else { return }

        let visibleRowsRange = storiesTableView.rows(in: storiesTableView.visibleRect)

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0
        storiesTableView.noteHeightOfRows(
            withIndexesChanged: IndexSet(integersIn: visibleRowsRange.toRange()!)
        )
        NSAnimationContext.endGrouping()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let story = stories[row]

        guard let cellView = tableView.make(withIdentifier: CommentCellView.reuseIdentifier, owner: self) as? StoryCellView else {
            let cellView = StoryCellView()
            cellView.configureFor(story)
            return cellView
        }
        
        cellView.configureFor(story)
        
        return cellView
    }
}
