//
//  User.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

struct User: Decodable {

    let id: String

    let karma: Int

    let created: Date

    let about: String?

    init?(dictionary: [String: Any?]) {
        guard
            let id = dictionary["id"] as? String,
            let karma = dictionary["karma"] as? Int,
            let createdEpoch = dictionary["created"] as? TimeInterval
        else {
            return nil
        }

        self.id = id
        self.karma = karma
        self.created = Date(timeIntervalSince1970: createdEpoch)
        self.about = dictionary["about"] as? String
    }
}
