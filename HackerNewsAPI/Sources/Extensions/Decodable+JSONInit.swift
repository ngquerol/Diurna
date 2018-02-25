//
//  Decodable+JSONInit.swift
//  HackerNewsAPI
//
//  Created by Nicolas Gaulard-Querol on 24/08/2019.
//  Copyright © 2019 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension Decodable {
    init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        self = try decoder.decode(Self.self, from: jsonData)
    }

    init(jsonDictionary: [String: Any?]) throws {
        try self.init(jsonData: JSONSerialization.data(withJSONObject: jsonDictionary))
    }
}
