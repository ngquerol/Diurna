//
//  Story.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import SwiftyJSON

class Story: Item {
    let score: Int
    let url: NSURL?
    let kids: [Int]
    let descendants: Int

    var rank: Int {
        let hoursSinceSubmission = abs(self.time.timeIntervalSinceNow / (60 * 60)),
        adjustedScore = self.score - 1,
        gravity = 1.8

        return adjustedScore / Int(pow(hoursSinceSubmission + 2.0, gravity))
    }

    override init?(json: JSON) {
        self.score = json["score"].intValue
        self.url = json["url"].URL
        self.kids = json["kids"].arrayValue.map { $0.intValue }
        self.descendants = json["descendants"].intValue
        super.init(json: json)
    }
}