//
//  MasterViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class StoriesViewController: NSViewController, NetworkingAware {

    // MARK: Outlets

    @IBOutlet var scrollView: NSScrollView! {
        didSet {
            scrollView.backgroundColor = Themes.current.backgroundColor
        }
    }

    @IBOutlet var tableView: NSTableView! {
        didSet {
            tableView.isHidden = true
            tableView.backgroundColor = Themes.current.backgroundColor
            prototypeCellView = tableView.makeView(
                withIdentifier: .storyCell,
                owner: self
            ) as? StoryCellView
        }
    }

    @IBOutlet var storiesToolbarView: NSView!

    @IBOutlet var storiesSearchField: NSSearchField!

    @IBOutlet var placeholderTextField: NSTextField! {
        didSet {
            placeholderTextField.isHidden = true
        }
    }

    @IBOutlet var progressOverlay: ProgressOverlayView! {
        didSet {
            progressOverlay.isHidden = true
            progressOverlay.progressIndicator.maxValue = 1.0
            progressOverlay.progressMessage.stringValue = "Loading stories..."
        }
    }

    // MARK: Properties

    private var stories: [Story] = [] {
        didSet {
            stories.sort()
            filteredStoriesDataSource = stories
        }
    }

    private var filteredStoriesDataSource: [Story] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private var selectedStory: Story?

    private var selectedStoriesType: StoryType = .new

    private var selectedStoriesCount = 10

    private var prototypeCellView: StoryCellView?

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
            selector: .updateStoriesCategory,
            name: .newCategorySelectedNotification,
            object: nil
        )
    }

    // MARK: Actions

    @IBAction func storiesCountButtonValueChanged(_ button: NSPopUpButton) {
        guard
            let storiesCountItem = button.selectedItem,
            let storiesCount = Int(storiesCountItem.title)
        else {
            return
        }

        selectedStoriesCount = storiesCount

        updateStories()
    }

    @IBAction func userDidTypeInSearchField(_ sender: NSSearchField) {
        let trimmedSearchString = sender.stringValue.trimmingCharacters(in: .whitespaces)

        guard trimmedSearchString.count > 0 else {
            return
        }

        filteredStoriesDataSource = stories.filter {
            $0.title.localizedCaseInsensitiveContains(storiesSearchField.stringValue)
        }
    }

    // MARK: Methods

    @objc func updateStoriesCategory(_ notification: Notification) {
        guard
            notification.name == .newCategorySelectedNotification,
            let categoryName = notification.userInfo?["selectedCategory"] as? String
        else {
            return
        }

        if let category = StoryType(rawValue: categoryName) {
            selectedStoriesType = category
            updateStories()
        } else {
            NSLog("%@: Unknown story type \"%@\"", className, categoryName)
        }
    }

    @objc func updateStories() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        placeholderTextField.isHidden = true
        tableView.isHidden = true
        progressOverlay.isHidden = false
        NSAnimationContext.endGrouping()

        let progress = Progress(totalUnitCount: Int64(selectedStoriesCount))

        progress.becomeCurrent(withPendingUnitCount: Int64(selectedStoriesCount))

        progressObservation = progress.observe(\.fractionCompleted, options: [.new, .initial]) { progress, _ in
            DispatchQueue.main.async {
                self.progressOverlay.progressIndicator.doubleValue = progress.fractionCompleted
            }
        }

        apiClient.fetchStories(of: selectedStoriesType, count: selectedStoriesCount) { [weak self] storiesResults in
            guard let `self` = self else { return }

            let stories: [Story] = storiesResults.compactMap {
                switch $0 {
                case let .success(story): return story
                case .failure:
                    return nil // TODO: Display (non-user facing) error
                }
            }

            self.progressObservation = nil

            self.stories = stories
            self.tableView.scrollRowToVisible(0)

            // Enqueue the animations on the main thread, to give the time to the progress
            // indicator to update to its maxValue.
            DispatchQueue.main.async {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.completionHandler = {
                    self.tableView.animator().isHidden = false
                }
                self.progressOverlay.animator().isHidden = true
                NSAnimationContext.endGrouping()
            }
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
    func numberOfRows(in _: NSTableView) -> Int {
        return filteredStoriesDataSource.count
    }
}

// MARK: - NSTableView Delegate

extension StoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let dummyCellView = prototypeCellView else {
            return tableView.rowHeight
        }

        dummyCellView.objectValue = filteredStoriesDataSource[row]
        dummyCellView.bounds.size.width = tableView.bounds.width
        dummyCellView.layoutSubtreeIfNeeded()

        return dummyCellView.fittingSize.height
    }

    func tableView(_ tableView: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        return tableView.makeView(withIdentifier: .storyRow, owner: self) as? StoryRowView
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: .storyCell, owner: self) as? StoryCellView,
            story = filteredStoriesDataSource[row]

        cellView?.objectValue = story

        return cellView
    }

    func tableViewColumnDidResize(_: Notification) {
        guard
            let visibleRowsRange = Range(tableView.rows(in: tableView.visibleRect))
        else {
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        tableView.noteHeightOfRows(
            withIndexesChanged: IndexSet(integersIn: visibleRowsRange)
        )
        NSAnimationContext.endGrouping()
    }

    func tableViewSelectionDidChange(_: Notification) {
        let newlySelectedStory = filteredStoriesDataSource[tableView.selectedRow]

        guard selectedStory?.id != newlySelectedStory.id else {
            return
        }

        selectedStory = newlySelectedStory

        NotificationCenter.default.post(
            name: .storySelectionNotification,
            object: self,
            userInfo: [
                "story": newlySelectedStory,
            ]
        )
    }
}

// MARK: - NSSearchFieldDelegate

extension StoriesViewController: NSSearchFieldDelegate {

    func searchFieldDidEndSearching(_: NSSearchField) {
        filteredStoriesDataSource = stories
    }
}
