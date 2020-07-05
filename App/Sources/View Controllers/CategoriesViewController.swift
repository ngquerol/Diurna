//
//  CategoriesViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 19/03/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

import HackerNewsAPI

class CategoriesViewController: NSViewController {
    // MARK: Outlets

    @IBOutlet var topSpacingConstraint: NSLayoutConstraint!

    @IBOutlet var tableView: NSTableView!

    // MARK: Properties

    private var didAppear = false

    // MARK: View Lifecycle

    override func viewDidAppear() {
        super.viewDidAppear()

        if !didAppear {
            didAppear.toggle()
            
            DispatchQueue.main.async {
                self.notifyCategoryChange()
            }
        }
    }

    // MARK: Functions

    func notifyCategoryChange() {
        guard 0 ..< StoryType.allCases.count ~= tableView.selectedRow else { return }

        NotificationCenter.default.post(
            name: .newCategorySelectedNotification,
            object: self,
            userInfo: ["selectedCategory": StoryType.allCases[tableView.selectedRow]]
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let newCategorySelectedNotification = Notification.Name(
        "NewCategorySelectedNotification")
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let categoryCell = NSUserInterfaceItemIdentifier("CategoryCell")
    static let categoryRow = NSUserInterfaceItemIdentifier("CategoryRow")
}

// MARK: - NSTableView Data Source

extension CategoriesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return StoryType.allCases.count
    }

    func tableViewSelectionDidChange(_: Notification) {
        notifyCategoryChange()
    }
}

// MARK: - NSTableView Delegate

extension CategoriesViewController: NSTableViewDelegate {
    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        return 30.0
    }

    func tableView(_ tableView: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        return tableView
            .makeView(withIdentifier: .categoryRow, owner: self) as? NoEmphasisTableRowView
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView
            .makeView(withIdentifier: .categoryCell, owner: self) as? NSTableCellView
        let selectedCategory = StoryType.allCases[row]

        cellView?.objectValue = selectedCategory
        cellView?.textField?.stringValue = selectedCategory.rawValue.capitalized
        cellView?.imageView?
            .image = NSImage(named: "\(selectedCategory.rawValue.capitalized)IconTemplate")

        return cellView
    }
}
