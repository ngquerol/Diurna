//
//  CategoriesViewController.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 19/03/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

class CategoriesViewController: NSViewController {

    @IBOutlet weak var categoriesTableView: NSTableView!

    private let storiesTypes = [
        HackerNewsAPI.TopStories.name: HackerNewsAPI.TopStories,
        HackerNewsAPI.NewStories.name: HackerNewsAPI.NewStories,
        HackerNewsAPI.JobStories.name: HackerNewsAPI.JobStories,
        HackerNewsAPI.ShowStories.name: HackerNewsAPI.ShowStories,
        HackerNewsAPI.AskStories.name: HackerNewsAPI.AskStories
    ]

    @IBAction func userDidSelectCategory(sender: NSTableView) {
        let selectedCategory = Array(storiesTypes.values)[sender.selectedRow]

        NSNotificationCenter.defaultCenter().postNotificationName(
            "NewStoriesCategorySelectedNotification",
            object: self,
            userInfo: ["selectedCategory": selectedCategory.name]
        )
    }
}

extension CategoriesViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return storiesTypes.count
    }
}

extension CategoriesViewController: NSTableViewDelegate {

    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let identifier = "CategoryRowView"

        guard let rowView = tableView.makeViewWithIdentifier(identifier, owner: nil) as? CategoryTableRowView else {
            let rowView = CategoryTableRowView()
            rowView.identifier = identifier
            return rowView
        }

        return rowView
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeViewWithIdentifier("CategoryColumn", owner: nil) as? NSTableCellView else {
            return nil
        }

        cellView.textField?.stringValue = Array(storiesTypes.keys)[row]

        return cellView
    }
}