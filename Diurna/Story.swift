//
//  Story.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

enum StoryType: String, Decodable {

    static let allValues = ["top", "best", "new", "job", "show", "ask"]

    case top

    case best

    case new

    case job

    case show

    case ask
}

struct Story: Item {

    let id: Int

    let time: Date

    let type: ItemType

    let title: String

    let score: Int

    let by: String

    let url: URL?

    let text: String?

    let descendants: Int

    let kids: [Int]

    var rank: Int {
        let hoursSinceSubmission = abs(time.timeIntervalSinceNow / (60 * 60)),
            adjustedScore = score - 1,
            gravity = 1.8

        return adjustedScore / Int(pow(hoursSinceSubmission + 2.0, gravity))
    }

    init?(dictionary: [String: Any?]) {
        guard
            let id = dictionary["id"] as? Int,
            let timeEpoch = dictionary["time"] as? TimeInterval,
            let typeString = dictionary["type"] as? String,
            let type = ItemType(rawValue: typeString),
            let title = dictionary["title"] as? String,
            let score = dictionary["score"] as? Int,
            let by = dictionary["by"] as? String
        else {
            return nil
        }

        self.id = id
        self.time = Date(timeIntervalSince1970: timeEpoch)
        self.type = type
        self.title = title
        self.score = score
        self.by = by
        self.url = URL(string: dictionary["url"] as? String ?? "")
        self.text = dictionary["text"] as? String
        self.descendants = dictionary["descendants"] as? Int ?? 0
        self.kids = dictionary["kids"] as? [Int] ?? []
    }
}

extension Story: Comparable {

    static func ==(lhs: Story, rhs: Story) -> Bool { return lhs.rank == rhs.rank }

    static func <(lhs: Story, _: Story) -> Bool { return lhs.rank < lhs.rank }
}
