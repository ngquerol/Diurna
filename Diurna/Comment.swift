//
//  Comment.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 24/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

/// This is a class for now, as NSOutlineView does not handle structs as its data source.
final class Comment: Item {

    let id: Int

    let time: Date

    let type: ItemType

    let parent: Int

    let deleted: Bool

    let text: String

    let by: String?

    let kidsIds: [Int]

    var kids: [Comment] = []

    init?(dictionary: [String: Any?]) {
        guard
            let id = dictionary["id"] as? Int,
            let timeEpoch = dictionary["time"] as? TimeInterval,
            let typeString = dictionary["type"] as? String,
            let type = ItemType(rawValue: typeString),
            let parent = dictionary["parent"] as? Int
        else {
            return nil
        }

        self.id = id
        self.time = Date(timeIntervalSince1970: timeEpoch)
        self.type = type
        self.parent = parent
        self.by = dictionary["by"] as? String ?? "[deleted]"
        self.text = dictionary["text"] as? String ?? ""
        self.kidsIds = (dictionary["kids"] as? [Int]) ?? []
        self.kids.reserveCapacity(self.kidsIds.count)
        self.deleted = dictionary["deleted"] as? Bool ?? false
    }
}
