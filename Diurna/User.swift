//
//  User.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa
import SwiftyJSON

struct User {
    let id: String
    let karma: Int32
    let created: NSDate
    let about: NSAttributedString?

    init?(json: JSON) {
        self.id = json["id"].stringValue
        self.karma = json["karma"].int32Value
        self.created = NSDate(timeIntervalSince1970: json["created"].doubleValue)

        if let about = json["about"].string {
            self.about = MarkupParser(input: about).toAttributedString()
        } else {
            self.about = nil
        }
    }
}