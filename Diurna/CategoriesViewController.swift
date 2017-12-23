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

    @IBOutlet var categoriesScrollView: NSScrollView!

    @IBOutlet var categoriesTableView: NSTableView!

    @IBOutlet var categoriesTableViewTopSpacingConstraint: NSLayoutConstraint!

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

    // MARK: Methods

    @objc func didEnterFullScreen(_ notification: Notification) {
        guard notification.name == .enterFullScreenNotification else { return }

        categoriesTableViewTopSpacingConstraint.constant = 0.0
    }

    @objc func didExitFullScreen(_ notification: Notification) {
        guard notification.name == .exitFullScreenNotification else { return }

        categoriesTableViewTopSpacingConstraint.constant = 29.0
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

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let categoryCell = NSUserInterfaceItemIdentifier("CategoryCell")
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
        guard 0 ..< StoryType.allValues.count ~= row else { return nil }

        return tableView.makeView(withIdentifier: .categoryRow, owner: self) as? NSTableRowView
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        return 30.0
    }

    func tableViewSelectionDidChange(_: Notification) {
        notifyCategoryChange()
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: .categoryCell, owner: self) as? NSTableCellView

        if let storyType = StoryType(rawValue: StoryType.allValues[row]) {
            let displayableName = storyType.rawValue.capitalized
            cellView?.imageView?.image = NSImage(named: NSImage.Name("\(displayableName)IconTemplate"))
            cellView?.imageView?.toolTip = "\(displayableName)"
        }

        return cellView
    }
}
