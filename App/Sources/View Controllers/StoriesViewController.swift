//
//  MasterViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit
import HackerNewsAPI
import OSLog

class StoriesViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet var scrollView: NSScrollView!

    @IBOutlet var tableView: NSTableView! {
        didSet {
            prototypeCellView =
                tableView.makeView(
                    withIdentifier: .storyCell,
                    owner: self
                ) as? StoryCellView
        }
    }

    @IBOutlet var toolbarLeadingSpaceConstraint: NSLayoutConstraint!

    @IBOutlet var reloadButton: NSButton! {
        didSet {
            reloadButton.toolTip = "Reload stories"
        }
    }

    @IBOutlet var storyCountButton: NSPopUpButton! {
        didSet {
            storyCountButton.toolTip = "Number of stories to load"
        }
    }

    @IBOutlet var searchField: NSSearchField!

    // MARK: Properties

    var progressOverlayView: NSView?

    private var stories: [Story] = [] {
        didSet {
            stories.sort { $0 > $1 }
            dataSource = stories
        }
    }

    private var dataSource: [Story] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var storiesCategory: StoryType?

    private var storiesCount: Int {
        let defaultStoriesCount = 10

        guard
            let countString = storyCountButton.titleOfSelectedItem
        else {
            return defaultStoriesCount
        }

        return Int(countString) ?? defaultStoriesCount
    }

    private var prototypeCellView: StoryCellView?

    // MARK: (De)initializer

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View Lifecycle

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .updateStoriesCategory,
            name: .newCategorySelectedNotification,
            object: nil
        )
    }

    // MARK: Actions

    @IBAction func userDidTypeInSearchField(_ target: NSSearchField) {
        let trimmedSearchString = searchField.stringValue.trimmingCharacters(
            in: .whitespaces)

        if trimmedSearchString.count > 0 {
            filterStories()
        } else {
            resetStories()
        }
    }

    @IBAction func userDidClickReloadButton(_: NSButton) {
        guard let category = storiesCategory else { return }

        updateStories(ofCategory: category, count: storiesCount)
    }

    @IBAction func userDidChangeStoriesCount(_: NSPopUpButton) {
        guard let category = storiesCategory else { return }

        updateStories(ofCategory: category, count: storiesCount)
    }

    // MARK: Methods

    @objc func updateStoriesCategory(_ notification: Notification) {
        guard
            notification.name == .newCategorySelectedNotification,
            let category = notification.userInfo?["selectedCategory"] as? StoryType,
            let count = Int(storyCountButton.titleOfSelectedItem ?? "")
        else {
            return
        }

        storiesCategory = category
        updateStories(ofCategory: category, count: count)
    }

    private func updateStories(ofCategory category: StoryType, count: Int) {
        showProgressOverlay(with: "Loading stories...")

        apiClient.fetchStories(of: category, count: count) { [weak self] storiesResults in
            let stories: [Story] = storiesResults.compactMap {
                switch $0 {
                case let .success(story): return story
                case let .failure(error):
                    os_log(
                        "Failed to retrieve story: %s",
                        log: .apiRequests,
                        type: .error,
                        error.localizedDescription
                    )
                    return nil
                }
            }

            // Update the table view's data source
            self?.stories = stories
            self?.tableView.scrollRowToVisible(0)

            self?.hideProgressOverlay()
        }
    }

    private func filterStories() {
        let trimmedSearchString = searchField.stringValue.trimmingCharacters(
            in: .whitespaces)

        dataSource = stories.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearchString)
        }
    }

    private func resetStories() {
        dataSource = stories
    }
}

// MARK: - HNAPIConsumer

extension StoriesViewController: HNAPIConsumer {}

// MARK: - ProgressShowing

extension StoriesViewController: ProgressShowing {}

// MARK: - Notifications

extension Notification.Name {
    static let storySelectionNotification = Notification.Name("StorySelectionNotification")
}

// MARK: - Selectors

extension Selector {
    fileprivate static let updateStoriesCategory = #selector(
        StoriesViewController
            .updateStoriesCategory(_:))
}

// MARK: - NSTableView Data Source

extension StoriesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return dataSource.count
    }
}

// MARK: - NSTableView Delegate

extension StoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let dummyCellView = prototypeCellView else {
            return tableView.rowHeight  // default row height
        }

        dummyCellView.objectValue = dataSource[row]
        dummyCellView.bounds.size.width = tableView.bounds.width
        dummyCellView.layoutSubtreeIfNeeded()

        let height = dummyCellView.fittingSize.height

        return height
    }

    func tableView(_ tableView: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        return tableView.makeView(withIdentifier: .storyRow, owner: self) as? StoryRowView
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: .storyCell, owner: self) as? StoryCellView
        let story = dataSource[row]

        cellView?.objectValue = story

        return cellView
    }

    func tableViewColumnDidResize(_: Notification) {
        guard
            let visibleRowsRange = Range(tableView.rows(in: tableView.visibleRect))
        else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            tableView.noteHeightOfRows(
                withIndexesChanged: IndexSet(integersIn: visibleRowsRange)
            )
        }
    }

    func tableViewSelectionDidChange(_: Notification) {
        NotificationCenter.default.post(
            name: .storySelectionNotification,
            object: self,
            userInfo: [
                "story": dataSource[tableView.selectedRow]
            ]
        )
    }
}

// MARK: - NSSearchFieldDelegate

extension StoriesViewController: NSSearchFieldDelegate {
    func searchFieldDidEndSearching(_: NSSearchField) {
        resetStories()
    }
}
