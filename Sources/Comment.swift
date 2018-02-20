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

    let deleted: Bool?

    let text: String?

    let by: String?

    let kidsIds: [Int]?

    var kids: [Comment]? = []

    enum CodingKeys: String, CodingKey {
        case id
        case time
        case type
        case parent
        case deleted
        case text
        case by
        case kidsIds = "kids"
    }
}
