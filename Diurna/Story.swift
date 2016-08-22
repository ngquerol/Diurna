//
//  Story.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import SwiftyJSON

class Story: Item {
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

    override init(json: JSON) {
        self.title = json["title"].stringValue
        self.score = json["score"].intValue
        self.by = json["by"].stringValue
        self.descendants = json["descendants"].intValue
        self.url = json["url"].URL
        self.text = json["text"].string
        self.kids = json["kids"].arrayValue.map { $0.intValue }

        super.init(json: json)
    }
}

extension Story: Comparable { }

func ==(lhs: Story, rhs: Story) -> Bool { return lhs.rank == rhs.rank }

func <(lhs: Story, rhs: Story) -> Bool { return lhs.rank < lhs.rank }
