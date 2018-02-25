//
//  User.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/02/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public struct User: Decodable {
    public let id: String

    public let karma: Int

    public let created: Date

    public let about: String?
}
