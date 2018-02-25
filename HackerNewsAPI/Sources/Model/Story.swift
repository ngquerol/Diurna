//
//  Story.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public typealias StoryType = Story.StoryType

public struct Story: Item {
    public let id: Int

    public let time: Date

    public let type: ItemType

    public let title: String

    public let score: Int

    public let by: String

    public let url: URL?

    public let text: String?

    public let descendants: Int?

    public let kidsIds: [Int]?

    public var kids: [Comment]?

    public var rank: Double {
        let gravity = 1.8
        let baseScore = Double(score - 1)
        let adjustedScore = baseScore > 0 ? pow(baseScore, 0.8) : baseScore
        let hoursSinceSubmission = abs(time.timeIntervalSinceNow) / 3600

        return adjustedScore / pow(hoursSinceSubmission + 2, gravity)
    }

    public enum StoryType: String, CaseIterable {
        case top
        case best
        case new
        case job
        case show
        case ask
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case time
        case type
        case title
        case score
        case by
        case url
        case text
        case descendants
        case kidsIds = "kids"
        case _kids
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(Int.self, forKey: .id)
        time = try values.decode(Date.self, forKey: .time)
        type = try values.decode(ItemType.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        score = try values.decode(Int.self, forKey: .score)
        by = try values.decode(String.self, forKey: .by)
        url = try values.decodeURLIfPresent(forKey: .url)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        descendants = try values.decodeIfPresent(Int.self, forKey: .descendants)
        kidsIds = try values.decodeIfPresent([Int].self, forKey: .kidsIds)
        kids = try values.decodeIfPresent([Comment].self, forKey: ._kids)
    }
}

extension Story: Comparable {
    public static func < (lhs: Story, rhs: Story) -> Bool {
        return lhs.rank < rhs.rank
    }
}
