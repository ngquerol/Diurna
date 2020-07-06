//
//  KeyedDecodingContainer+decodeURL.swift
//  HackerNewsAPI
//
//  Created by Nicolas Gaulard-Querol on 01/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeURL(forKey key: Self.Key) throws -> URL {
        let urlString = try decode(String.self, forKey: key)

        guard
            let encodedUrlString = urlString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Failed to percent-encode URL string \"\(urlString)\""
            )
        }

        guard let url = URL(string: encodedUrlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Failed to decode URL from input string \"\(encodedUrlString)\""
            )
        }

        return url
    }

    func decodeURLIfPresent(forKey key: Self.Key) throws -> URL? {
        guard let urlString = try decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        guard
            let encodedUrlString = urlString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Failed to percent-encode URL string \"\(urlString)\""
            )
        }

        guard let url = URL(string: encodedUrlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Failed to decode URL from input string \"\(encodedUrlString)\""
            )
        }

        return url
    }
}
