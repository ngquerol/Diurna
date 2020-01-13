//
//  Item.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

enum ItemType: String, JSONDecodable {
    case comment
    case job
    case story
    case poll
    case pollopt
}

protocol Item: JSONDecodable, Hashable {

    var id: Int { get }

    var time: Date { get }

    var type: ItemType { get }
}

// MARK: - Hashable

extension Hashable where Self: Item {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
