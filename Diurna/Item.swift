//
//  Item.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa
import SwiftyJSON

class Item: Equatable {
    let id: Int
    let time: NSDate
    let type: String
    let title: String
    let text: String
    let by: String

    init?(json: JSON) {
        self.text = json["text"].stringValue
        self.id = json["id"].intValue
        self.time = NSDate(timeIntervalSince1970: json["time"].doubleValue)
        self.type = json["type"].stringValue
        self.title = json["title"].stringValue
        self.by = json["by"].stringValue
    }
}

func == (x: Item, y: Item) -> Bool {
    return x.id == y.id
}