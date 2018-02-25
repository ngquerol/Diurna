//
//  Comment.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 24/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public struct Comment: Item {
    public let id: Int

    public let time: Date

    public let type: ItemType

    public let parent: Int

    public let deleted: Bool?

    public let text: String?

    public let by: String?

    public let kidsIds: [Int]?

    public var kids: [Comment]?

    private enum CodingKeys: String, CodingKey {
        case id
        case time
        case type
        case parent
        case deleted
        case text
        case by
        case kidsIds = "kids"
        case _kids
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(Int.self, forKey: .id)
        time = try values.decode(Date.self, forKey: .time)
        type = try values.decode(ItemType.self, forKey: .type)
        parent = try values.decode(Int.self, forKey: .parent)
        deleted = try values.decodeIfPresent(Bool.self, forKey: .deleted)
        by = try values.decodeIfPresent(String.self, forKey: .by)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        kidsIds = try values.decodeIfPresent([Int].self, forKey: .kidsIds)
        kids = try values.decodeIfPresent([Comment].self, forKey: ._kids)
    }
}
