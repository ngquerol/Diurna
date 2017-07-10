//
//  APIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

protocol APIEndpoint {
    var version: Int { get }
    var baseURL: URL { get }
    var path: URL { get }
}

enum HackerNewsAPI {
    case item(withId: Int)
    case user(withName: String)
    case stories(ofType: StoryType)
}

extension HackerNewsAPI: APIEndpoint {
    var version: Int { return 0 }
    var baseURL: URL { return URL(string: "https://hacker-news.firebaseio.com/v\(version)")! }
    var path: URL {
        switch self {
        case .item(let id): return baseURL.appendingPathComponent("item/\(id)")
        case .user(let id): return baseURL.appendingPathComponent("user/\(id)")
        case .stories(let type):
            switch type {
            case .top: return baseURL.appendingPathComponent("topstories")
            case .best: return baseURL.appendingPathComponent("beststories")
            case .new: return baseURL.appendingPathComponent("newstories")
            case .job: return baseURL.appendingPathComponent("jobstories")
            case .show: return baseURL.appendingPathComponent("showstories")
            case .ask: return baseURL.appendingPathComponent("askstories")
            }
        }
    }
}

enum APIError: Error {
    case clientError(String)
    case networkError(Error)
    case invalidHTTPResponse(HTTPURLResponse)
    case emptyResponse
    case invalidJSON
    case unknown

    var localizedDescription: String {
        switch self {
        case .clientError(let reason): return "The client failed to execute the request: \(reason)"
        case .networkError(let error): return error.localizedDescription
        case .invalidHTTPResponse(let response): return "The server HTTP response status code indicated an error: HTTP \(response.statusCode)"
        case .emptyResponse: return "The server's response body was empty"
        case .invalidJSON: return "The server's JSON response could not be parsed"
        case .unknown: return "Unknown error"
        }
    }
}

protocol HackerNewsAPIClient {
    func fetchStories(of type: StoryType, count: Int, completion: @escaping (_ result: [Result<Story, APIError>]) -> Void)
    func fetchComments(of story: Story, completion: @escaping (_ result: [Result<Comment, APIError>]) -> Void)
    func fetchUser(with name: String, completion: @escaping (_ result: Result<User, APIError>) -> Void)
}
