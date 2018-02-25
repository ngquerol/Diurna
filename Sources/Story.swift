//
//  Story.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

enum StoryType: String, JSONDecodable {

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

    let descendants: Int?

    let kids: [Int]?

    var rank: Double {
        let gravity = 1.8,
            baseScore = Double(score - 1),
            adjustedScore = baseScore > 0 ? pow(baseScore, 0.8) : baseScore,
            hoursSinceSubmission = abs(time.timeIntervalSinceNow) / 3600

        return adjustedScore / pow(hoursSinceSubmission + 2, gravity)
    }
}

extension Story: Comparable {

    static func < (lhs: Story, rhs: Story) -> Bool {
        return lhs.rank < rhs.rank
    }
}
