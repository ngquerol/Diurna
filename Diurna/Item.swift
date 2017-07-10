//
//  Item.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 21/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

enum ItemType: String, Decodable {
    case comment
    case job
    case story
    case poll
    case pollopt
}

protocol Item: Decodable {

    var id: Int { get }

    var time: Date { get }

    var type: ItemType { get }

    init?(dictionary: [String: Any?])
}

extension Equatable where Self: Item { }

func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id
}
