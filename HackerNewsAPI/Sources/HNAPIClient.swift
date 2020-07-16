//
//  APIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 01/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

// MARK: - Public API

public typealias HNAPIResult<T> = Result<T, HNAPIError>

public typealias HNAPIResultCallback<T> = (HNAPIResult<T>) -> Void

public typealias HNAPIResultsCallback<T> = ([HNAPIResult<T>]) -> Void

/// [Hacker News](https://news.ycombinator.com) API client.
/// - Note: Clients always assume being called on the main thread, and also execute their completion callbacks on the main thread.
public protocol HNAPIClient {
    var requestTimeout: TimeInterval { get set }

    func fetchStories(
        of type: StoryType, count: Int,
        completion: @escaping HNAPIResultsCallback<Story>
    )

    func fetchComments(
        of story: Story,
        completion: @escaping HNAPIResultsCallback<Comment>
    )

    func fetchUser(
        with name: String,
        completion: @escaping HNAPIResultCallback<User>
    )
}

/// Errors thrown while interacting with the Hacker News API.
public enum HNAPIError: Error {
    case genericNetworkError(Error)
    case invalidHTTPStatus(Int)
    case invalidJSON(Error)
    case requestTimedOut
    case emptyResponse
    case unknown
}

extension HNAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .genericNetworkError(error):
            return error.localizedDescription
        case let .invalidHTTPStatus(status):
            return "The server's HTTP response status code was not expected: HTTP \(status)"
        case let .invalidJSON(error):
            return "The server's JSON response could not be parsed: \(error.localizedDescription)"
        case .requestTimedOut:
            return "The server took too long to respond"
        case .emptyResponse:
            return "The server's response body was empty"
        case .unknown:
            return nil
        }
    }
}

// MARK: - End Public API

protocol APIEndpoint {
    var version: Int { get }
    var baseURL: URL { get }
    var path: URL { get }
}

enum HNAPI {
    case item(withId: Int)
    case user(withName: String)
    case stories(ofType: StoryType)
}

extension HNAPI: APIEndpoint {
    var version: Int { return 0 }
    var baseURL: URL { return URL(string: "https://hacker-news.firebaseio.com/v\(version)")! }

    var path: URL {
        switch self {
        case let .item(id): return baseURL.appendingPathComponent("item/\(id)")
        case let .user(id): return baseURL.appendingPathComponent("user/\(id)")
        case let .stories(type):
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

    var firebasePath: String {
        let completePath = path.path,
            pathStartIndex = completePath.index(after: completePath.startIndex)

        return String(completePath.suffix(from: pathStartIndex))
    }
}
