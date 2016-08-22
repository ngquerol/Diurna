//
//  Comment.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 24/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import SwiftyJSON

class Comment: Item {
    let parent: Int
    let deleted: Bool
    let text: NSAttributedString?
    let by: String?
    let kidsIds: [Int]
    var kids: [Comment]

    override init(json: JSON) {
        self.parent = json["parent"].intValue
        self.deleted = json["deleted"].bool ?? false
        self.text = json["text"].string?.parseMarkup()
        self.by = json["by"].string
        self.kidsIds = json["kids"].arrayValue.map { $0.intValue }
        self.kids = []

        super.init(json: json)
    }
}
