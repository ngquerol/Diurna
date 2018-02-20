//
//  WebRouting.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/08/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

protocol WebItem {
    var baseURL: URL { get }
    var path: URL { get }
}

enum HackerNewsWebpage {
    case item(Int)
    case user(String)

    var name: String {
        switch self {
        case .item: return "item"
        case .user: return "user"
        }
    }
}

extension HackerNewsWebpage: WebItem {
    var baseURL: URL { return URL(string: "https://news.ycombinator.com")! }
    var path: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!

        switch self {
        case let .item(id):
            components.queryItems = [URLQueryItem(name: "id", value: "\(id)")]
            return components.url!.appendingPathComponent(name)

        case let .user(id):
            components.queryItems = [URLQueryItem(name: "id", value: "\(id)")]
            return components.url!.appendingPathComponent(name)
        }
    }
}
