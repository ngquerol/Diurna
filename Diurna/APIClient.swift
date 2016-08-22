//
//  APIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol APIClient {
    func fetchStories(of type: StoryType, count: Int, completion: @escaping (_ data: [Story]) -> Void)
    func fetchComments(of story: Story, completion: @escaping (_ data: [Comment]) -> Void)
    func fetchUser(with id: String, completion: @escaping (_ data: User) -> Void)
}

enum APIError: Error {
    case networkError(NSError)
    case invalidHTTPResponse(HTTPURLResponse)
    case emptyResponse
    case unknown
}

extension APIError: CustomStringConvertible {
    var description: String {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .invalidHTTPResponse(let response): return "Invalid HTTP status code: \(response.statusCode)"
        case .emptyResponse: return "Response body is empty"
        case .unknown: return "Unknown / Unhandled error"
        }
    }
}

struct MockAPIClient {
    static let sharedInstance = MockAPIClient()

    fileprivate var mockJSON = [String:[Int:JSON]]()

    private init() {
        for type in StoryType.allValues {
            mockJSON[type] = [:]

            guard let path = Bundle.main.path(forResource: "TestData/\(type)stories", ofType: "json"),
                let fileContent = try? String(contentsOfFile: path, encoding: String.Encoding.utf8),
                let stringData = fileContent.data(using: String.Encoding.utf8) else {
                    continue
            }

            JSON(data: stringData).arrayValue.forEach {
                let storyID = $0.dictionaryValue["id"]!.intValue
                mockJSON[type]![storyID] = $0
            }
        }
    }

    fileprivate func loadComments(json: [JSON]) -> [Comment] {
        var comments = [Comment]()

        for commentJSON in json {
            let comment = Comment(json: commentJSON),
                kidsJSON = commentJSON["kids"].arrayValue

            if !kidsJSON.isEmpty {
                comment.kids = loadComments(json: kidsJSON)
            }

            comments.append(comment)
        }

        return comments
    }
}

extension MockAPIClient: APIClient {
    func fetchStories(of type: StoryType, count: Int, completion: @escaping (_ data: [Story]) -> Void) {
        if let stories = mockJSON[type.rawValue] {
            DispatchQueue.main.async {
                completion(stories.values.prefix(count).flatMap { Story(json: $0) })
            }
        } else {
            DispatchQueue.main.async {
                completion([Story]())
            }
        }
    }

    func fetchComments(of story: Story, completion: @escaping (_ data: [Comment]) -> Void) {
        for json in mockJSON.values {
            guard let story = json[story.id] else { continue }

            DispatchQueue.main.async {
                completion(self.loadComments(json: story["kids"].arrayValue))
            }
            return
        }

        DispatchQueue.main.async {
            completion([])
        }
    }

    func fetchUser(with id: String, completion: @escaping (_ data: User) -> Void) {
        let fakeUserJSON = JSON([
            "id": id,
            "karma": 42,
            "created": 1304177034,
            "about": "Your bones don't break, mine do. That's clear. Your cells react to bacteria and viruses differently than mine. You don't get sick, I do. That's also clear. But for some reason, you and I react the exact same way to water. We swallow it too fast, we choke. We get some in our lungs, we drown. However unreal it may seem, we are connected, you and I. We're on the same curve, just on opposite ends."
        ])

        DispatchQueue.main.async {
            completion(User(json: fakeUserJSON))
        }
    }
}

// TODO: Error Handling 😜
struct FirebaseAPIClient {

    // MARK: Properties
    static let sharedInstance = FirebaseAPIClient()
    private var URLSession: Foundation.URLSession

    // MARK: Initializers
    private init() {
        let sessionConfig = URLSessionConfiguration.default

        sessionConfig.timeoutIntervalForRequest = 10.0
        sessionConfig.timeoutIntervalForResource = 20.0
        sessionConfig.httpShouldUsePipelining = true
        sessionConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Accept-Charset": "utf-8",
            "Accept-Encoding": "gzip, deflate"
        ]

        self.URLSession = Foundation.URLSession(configuration: sessionConfig)
    }

    // MARK: Methods
    fileprivate func fetchStoriesIds(of type: StoryType, count: Int = 500, completion: @escaping ([Int]) -> Void) {
        httpGet(HackerNewsAPI.stories(type).path, dataHandler: { data in
                let storiesIds = JSON(data: data)
                    .arrayValue
                    .prefix(count)
                    .map { $0.intValue }

                DispatchQueue.main.async {
                    completion(storiesIds)
                }
            }, errorHandler: { err in
                NSLog(err.description)
            }
        )
    }

    fileprivate func fetchComment(_ id: Int, completion: @escaping (_ data: Comment) -> Void) {
        httpGet(HackerNewsAPI.item(id).path, dataHandler: { data in
                let comment = Comment(json: JSON(data: data))

                guard !comment.kidsIds.isEmpty else {
                    completion(comment)
                    return
                }

                let fetchGroup = DispatchGroup()
                var children = [Comment?](repeating: nil, count: comment.kidsIds.count)

                for (i, id) in comment.kidsIds.enumerated() {
                    fetchGroup.enter()
                    self.fetchComment(id) { childComment in
                        children[i] = childComment
                        fetchGroup.leave()
                    }
                }

                fetchGroup.notify(queue: DispatchQueue.main) {
                    comment.kids = children.flatMap { $0 }
                    completion(comment)
                }
            }, errorHandler: { err in
                NSLog(err.description)
            }
        )
    }

    fileprivate func httpGet(_ url: URL, dataHandler: @escaping (_ data: Data) -> Void, errorHandler: @escaping (_ error: APIError) -> Void) {
        URLSession.dataTask(with: url) { data, response, error in
            switch (data, response as? HTTPURLResponse, error) {
            case (_, _, let .some(error)):
                errorHandler(.networkError(error as NSError))

            case (_, let .some(response), _) where !(200..<300 ~= response.statusCode):
                errorHandler(.invalidHTTPResponse(response))

            case (let data, _, _) where data == nil || data?.count == 0:
                errorHandler(.emptyResponse)

            case (let .some(data), _, _):
                dataHandler(data)

            default:
                errorHandler(.unknown)
            }
        }.resume()
    }
}

extension FirebaseAPIClient: APIClient {
    func fetchStories(of type: StoryType, count: Int, completion: @escaping (_ data: [Story]) -> Void) {
        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(count))
        var stories = [Story?](repeating: nil, count: count)

        fetchGroup.enter()
        fetchStoriesIds(of: type, count: count) { storiesIds in
            for (i, id) in storiesIds.enumerated() {
                fetchGroup.enter()
                self.httpGet(HackerNewsAPI.item(id).path, dataHandler: { data in
                        stories[i] = Story(json: JSON(data: data))
                        progress.completedUnitCount += 1
                        fetchGroup.leave()
                    }, errorHandler: { err in
                        NSLog(err.description)
                        progress.completedUnitCount += 1
                        fetchGroup.leave()
                    }
                )
            }
            fetchGroup.leave()
        }

        fetchGroup.notify(queue: DispatchQueue.main) {
            completion(stories.flatMap { $0 })
        }
    }

    func fetchComments(of story: Story, completion: @escaping (_ data: [Comment]) -> Void) {
        guard !story.kids.isEmpty else {
            completion([])
            return
        }

        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(story.kids.count))
        var topLevelComments = [Comment?](repeating: nil, count: story.kids.count)

        for (i, id) in story.kids.enumerated() {
            fetchGroup.enter()
            fetchComment(id) { comment in
                topLevelComments[i] = comment
                progress.completedUnitCount += 1
                fetchGroup.leave()
            }
        }

        fetchGroup.notify(queue: DispatchQueue.main) {
            completion(topLevelComments.flatMap { $0 })
        }
    }

    func fetchUser(with id: String, completion: @escaping (_ data: User) -> Void) {
        httpGet(HackerNewsAPI.user(id).path, dataHandler: { data in
                DispatchQueue.main.async {
                    completion(User(json: JSON(data: data)))
                }
            }, errorHandler: { err in
                NSLog(err.description)
            }
        )
    }
}
