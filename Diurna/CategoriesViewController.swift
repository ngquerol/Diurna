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
    @IBOutlet weak var categoriesTableView: NSTableView!

    // MARK: View lifecycle
    override func viewDidAppear() {
        super.viewDidAppear()

        notifyCategoryChange()
    }

    // MARK: Methods
    @IBAction func categoriesTableViewSelectionChanged(_ sender: NSTableView) {
        notifyCategoryChange()
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

// MARK: - NSTableView Data Source
extension CategoriesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return StoryType.allValues.count
    }
}

// MARK: - NSTableView Delegate
extension CategoriesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let rowView = tableView.make(withIdentifier: CategoryRowView.rowIdentifier, owner: self) as? CategoryRowView else {
            let rowView = CategoryRowView()
            rowView.identifier = CategoryRowView.rowIdentifier
            return rowView
        }

        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.make(withIdentifier: "CategoryCell", owner: self) as? NSTableCellView else {
            return nil
        }

        if let storyType = StoryType(rawValue: StoryType.allValues[row]) {
            let displayableName = storyType.rawValue.capitalized
            cellView.imageView?.image = NSImage(named: "\(displayableName)IconTemplate")
            cellView.imageView?.toolTip = "\(displayableName)"
        }
        
        return cellView
    }
}
