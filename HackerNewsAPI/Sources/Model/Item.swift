//
//  Item.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public enum ItemType: String, Decodable {
    case comment
    case job
    case story
    case poll
    case pollopt
}

public protocol Item: Decodable, Hashable {
    var id: Int { get }

    var time: Date { get }

    var type: ItemType { get }
}

// MARK: - Hashable

extension Hashable where Self: Item {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
