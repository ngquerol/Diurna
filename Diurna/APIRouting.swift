//
//  APIRouter.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 27/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

protocol APIEndpoint {
    var version: Int { get }
    var baseURL: URL { get }
    var path: URL { get }
}

enum StoryType: String {
    static let allValues = ["top", "best", "new", "job", "show", "ask"]
    case top = "top"
    case best = "best"
    case new = "new"
    case job = "job"
    case show = "show"
    case ask = "ask"
}

enum HackerNewsAPI {
    case item(Int)
    case user(String)
    case stories(StoryType)
}

extension HackerNewsAPI: APIEndpoint {
    var version: Int { return 0 }
    var baseURL: URL { return URL(string: "https://hacker-news.firebaseio.com/v\(version)")! }
    var path: URL {
        switch self {
        case .item(let id): return baseURL.appendingPathComponent("item/\(id).json")
        case .user(let id): return baseURL.appendingPathComponent("user/\(id).json")
        case .stories(let type):
            switch type {
            case .top: return baseURL.appendingPathComponent("topstories.json")
            case .best: return baseURL.appendingPathComponent("beststories.json")
            case .new: return  baseURL.appendingPathComponent("newstories.json")
            case .job: return baseURL.appendingPathComponent("jobstories.json")
            case .show: return baseURL.appendingPathComponent("showstories.json")
            case .ask: return baseURL.appendingPathComponent("askstories.json")
            }
        }
    }
}
