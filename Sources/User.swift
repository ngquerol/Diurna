//
//  User.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

struct User: JSONDecodable {

    let id: String

    let karma: Int

    let created: Date

    let about: String?
}
