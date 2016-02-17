//
//  APIRouter.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

protocol APIEndpoint {
    var version: Int { get }
    var baseURL: NSURL { get }
    var path: NSURL { get }
}

enum HackerNewsAPI {
    case Item(Int)
    case User(String)
    case TopStories
    case NewStories
}

extension HackerNewsAPI : APIEndpoint {
    var version: Int { return 0 }
    var baseURL: NSURL { return NSURL(string: "https://hacker-news.firebaseio.com/v\(self.version)")! }
    var path: NSURL {
        switch self {
        case .Item(let id): return baseURL.URLByAppendingPathComponent("/item/\(id).json")
        case .User(let id): return baseURL.URLByAppendingPathComponent("/user/\(id).json")
        case .TopStories: return baseURL.URLByAppendingPathComponent("/topstories.json")
        case .NewStories: return baseURL.URLByAppendingPathComponent("/newstories.json")
        }
    }
}
