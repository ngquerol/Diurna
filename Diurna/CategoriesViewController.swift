//
//  CategoriesViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 19/03/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CategoriesViewController: NSViewController {

    // MARK: Outlets
    @IBOutlet var categoriesVisualEffectView: NSVisualEffectView!
    
    @IBOutlet var categoriesScrollView: NSScrollView! {
        didSet {
            categoriesScrollView.automaticallyAdjustsContentInsets = false
            categoriesScrollView.contentInsets.top = topEdgeInset
        }
    }

    @IBOutlet weak var categoriesTableView: NSTableView!

    // MARK: Properties
    private let topEdgeInset: CGFloat = 29.0

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        categoriesVisualEffectView.appearance = Themes.current.visualEffectAppearance
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(
            self,
            selector: .didEnterFullScreen,
            name: .enterFullScreenNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: .didExitFullScreen,
            name: .exitFullScreenNotification,
            object: nil
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        notifyCategoryChange()
    }

    // MARK: (De)initializer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Actions
    @IBAction func categoriesTableViewSelectionChanged(_: NSTableView) {
        notifyCategoryChange()
    }

    // MARK: Methods
    @objc func didEnterFullScreen(_ notification: Notification) {
        guard notification.name == .enterFullScreenNotification else { return }

        categoriesScrollView.contentInsets.top = 0.0
    }

    @objc func didExitFullScreen(_ notification: Notification) {
        guard notification.name == .exitFullScreenNotification else { return }

        categoriesScrollView.contentInsets.top = topEdgeInset
    }

    private func notifyCategoryChange() {
        guard let selectedCategory = StoryType(rawValue: StoryType.allValues[categoriesTableView.selectedRow]) else { return }

        NotificationCenter.default.post(
            name: .newCategorySelectedNotification,
            object: self,
            userInfo: ["selectedCategory": selectedCategory.rawValue]
        )
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let newCategorySelectedNotification = Notification.Name("NewCategorySelectedNotification")
}

// MARK: - Selectors
private extension Selector {
    static let didEnterFullScreen = #selector(CategoriesViewController.didEnterFullScreen(_:))
    static let didExitFullScreen = #selector(CategoriesViewController.didExitFullScreen(_:))
}

// MARK: - NSTableView Data Source
extension CategoriesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return StoryType.allValues.count
    }
}

// MARK: - NSTableView Delegate
extension CategoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let rowView = tableView.makeView(withIdentifier: CategoryRowView.reuseIdentifier, owner: self) as? CategoryRowView else {
            let rowView = CategoryRowView()
            rowView.identifier = CategoryRowView.reuseIdentifier
            return rowView
        }

        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let categoryCellIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier("CategoryCell")

        guard let cellView = tableView.makeView(withIdentifier: categoryCellIdentifier, owner: self) as? NSTableCellView else {
            return nil
        }

        if let storyType = StoryType(rawValue: StoryType.allValues[row]) {
            let displayableName = storyType.rawValue.capitalized
            cellView.imageView?.image = NSImage(named: NSImage.Name("\(displayableName)IconTemplate"))
            cellView.imageView?.toolTip = "\(displayableName)"
        }

        return cellView
    }
}
