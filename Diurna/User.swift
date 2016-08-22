//
//  User.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import SwiftyJSON

struct User {
    let id: String
    let karma: Int
    let created: Date
    let about: NSAttributedString?

    init(json: JSON) {
        id = json["id"].stringValue
        karma = json["karma"].intValue
        created = Date(timeIntervalSince1970: json["created"].doubleValue)
        if let aboutString = json["about"].string {
            about = aboutString.parseMarkup()
        } else {
            about = nil
        }
    }
}
