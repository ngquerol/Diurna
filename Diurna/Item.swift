//
//  Item.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import SwiftyJSON

class Item {
    let id: Int
    let time: Date
    let type: String

    init(json: JSON) {
        id = json["id"].intValue
        time = Date(timeIntervalSince1970: json["time"].doubleValue)
        type = json["type"].stringValue
    }
}

extension Item: Equatable { }

func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id
}
