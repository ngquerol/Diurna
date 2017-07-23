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

    @IBOutlet weak var storiesScrollView: NSScrollView! {
        didSet {
            storiesScrollView.backgroundColor = Themes.current.backgroundColor
        }
    }

    @IBOutlet weak var storiesTableView: NSTableView! {
        didSet {
            storiesTableView.isHidden = true
            storiesTableView.backgroundColor = Themes.current.backgroundColor
        }
    }

    @IBOutlet weak var storiesPlaceholderTextField: NSTextField! {
        didSet {
            storiesPlaceholderTextField.isHidden = true
        }
    }

    @IBOutlet weak var storiesProgressIndicator: NSProgressIndicator!

    @IBOutlet weak var storiesProgressLabel: NSTextField!

    @IBOutlet weak var storiesProgressOverlay: NSStackView! {
        didSet {
            storiesProgressOverlay.isHidden = true
        }
    }

    @IBOutlet weak var storiesTypeTextField: NSTextField! {
        didSet {
            storiesTypeTextField.textColor = Themes.current.normalTextColor
        }
    }

    @IBOutlet weak var storiesCountPopUpButton: NSPopUpButton! {
        didSet {
            storiesCountPopUpButton.toolTip = "Number of stories to display"
        }
    }

    // MARK: Properties
    fileprivate var storiesDataSource: [Story] = [] {
        didSet {
            storiesDataSource.sort()
            storiesTableView.reloadData()
        }
    }

    fileprivate var selectedStory: Story?

    private let API: HackerNewsAPIClient = FirebaseAPIClient.sharedInstance

    private var selectedStoriesType: StoryType = .new

    private var selectedStoriesCount = 10

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
    @IBAction func userDidSelectStory(_: NSTableView) {
        guard selectedStory?.id != storiesDataSource[storiesTableView.selectedRow].id else { return }

        selectedStory = storiesDataSource[storiesTableView.selectedRow]

        NotificationCenter.default.post(
            name: .storySelectionNotification,
            object: self,
            userInfo: [
                "story": storiesDataSource[storiesTableView.selectedRow],
            ]
        )
    }

    @IBAction private func storiesCountButtonValueChanged(_: NSPopUpButton) {
        guard let storiesCountItem = storiesCountPopUpButton.selectedItem,
            let storiesCount = Int(storiesCountItem.title) else {
            return
        }

        selectedStoriesCount = storiesCount

        updateStories()
    }

    // MARK: Methods
    @objc func updateStoriesCategory(_ notification: Notification) {
        guard notification.name == .newCategorySelectedNotification,
            let categoryName = notification.userInfo?["selectedCategory"] as? String else {
            return
        }

        if let category = StoryType(rawValue: categoryName) {
            storiesTypeTextField.stringValue = categoryName.capitalized
            selectedStoriesType = category
            updateStories()
        } else {
            NSLog("%@: Unknown story type \"%@\"", className, categoryName)
        }
    }

    func updateStories() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.allowsImplicitAnimation = true
        storiesPlaceholderTextField.isHidden = true
        storiesTableView.isHidden = true
        storiesProgressOverlay.isHidden = false
        NSAnimationContext.endGrouping()

        let progress = Progress(totalUnitCount: Int64(selectedStoriesCount))
        progress.becomeCurrent(withPendingUnitCount: Int64(selectedStoriesCount))

        progressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) { object, _ in
            DispatchQueue.main.async {
                self.storiesProgressIndicator.doubleValue = object.fractionCompleted
            }
        }

        API.fetchStories(of: selectedStoriesType, count: selectedStoriesCount) { [weak self] storiesResults in
            guard let `self` = self else { return }

            var fetchErrors = [APIError]()
            let stories: [Story] = storiesResults.flatMap {
                switch $0 {
                case let .success(story): return story
                case let .failure(error):
                    fetchErrors.append(error)
                    return nil
                }
            }

            fetchErrors.forEach { NSLog("Failed to fetch story: %@", $0.localizedDescription) }

            self.storiesDataSource = stories
            self.storiesTableView.scrollRowToVisible(0)

            // Enqueue the animations on the main thread, to give the time to the progress
            // indicator to update to its maxValue.
            DispatchQueue.main.async {
                NSAnimationContext.beginGrouping()
                self.storiesProgressOverlay.animator().isHidden = true
                NSAnimationContext.current.completionHandler = {
                    self.storiesTableView.animator().isHidden = false
                }
                NSAnimationContext.endGrouping()
            }

            progress.resignCurrent()
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
        return storiesDataSource.count
    }
}

// MARK: - NSTableView Delegate
extension StoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let cellView = tableView.makeView(withIdentifier: StoryCellView.reuseIdentifier, owner: self) as? StoryCellView else {
            return tableView.rowHeight
        }

        cellView.configureFor(storiesDataSource[row])

        return cellView.heightForWidth(tableView.frame.width)
    }

    func tableViewColumnDidResize(_ notification: Notification) {
        guard let visibleRowsRange = Range(storiesTableView.rows(in: storiesTableView.visibleRect)) else {
            return
        }

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0
        storiesTableView.noteHeightOfRows(
            withIndexesChanged: IndexSet(integersIn: visibleRowsRange)
        )
        NSAnimationContext.endGrouping()
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard 0 ..< storiesDataSource.count ~= row else { return nil }

        guard let rowView = tableView.makeView(withIdentifier: StoryRowView.reuseIdentifier, owner: self) as? StoryRowView else {
            let rowView = StoryRowView(frame: .zero)
            rowView.identifier = StoryRowView.reuseIdentifier
            return rowView
        }

        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: StoryCellView.reuseIdentifier, owner: self) as? StoryCellView,
            story = storiesDataSource[row]
        
        cellView?.configureFor(story)
        cellView?.objectValue = storiesDataSource[row]

        return cellView
    }
}
