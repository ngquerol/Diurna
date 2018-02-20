//
//  JSONDecodable.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 15/09/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

protocol JSONDecodable: Decodable {
    typealias JSON = [String: Any]
    init?(jsonData: Data)
    init?(json: JSON)
}

// TODO: throws instead of -> nil

extension JSONDecodable {

    init?(jsonData: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        do {
            self = try decoder.decode(Self.self, from: jsonData)
        } catch let error {
            NSLog("Could not decode JSON: %@", error.localizedDescription)
            return nil
        }
    }

    init?(json: JSON) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            self.init(jsonData: data)
        } catch let error {
            NSLog("Could not decode JSON: %@", error.localizedDescription)
            return nil
        }
    }
}
