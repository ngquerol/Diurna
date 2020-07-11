//
//  RESTHNAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 11/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public struct RESTHNAPIClient {
    // MARK: Properties

    public var requestTimeout: TimeInterval = 10.0

    private let jsonDecoder = JSONDecoder()

    private var urlSession: URLSession

    // MARK: Initializer

    public init() {
        let sessionConfig = URLSessionConfiguration.default

        sessionConfig.timeoutIntervalForRequest = requestTimeout
        sessionConfig.timeoutIntervalForResource = requestTimeout * 2
        sessionConfig.httpShouldUsePipelining = true
        sessionConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Accept-Charset": "utf-8",
            "Accept-Encoding": "gzip, deflate",
        ]

        urlSession = URLSession(configuration: sessionConfig)
    }

    // MARK: Methods

    private func validateResponse<T: Decodable>(
        _ data: Data?, _ response: URLResponse?,
        _ error: Error?
    ) -> Result<T, HNAPIError> {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, .some(error)):
            return .failure(.genericNetworkError(error))
            
        case let (_, .some(response), _) where !(200..<300 ~= response.statusCode):
            return .failure(.invalidHTTPStatus(response.statusCode))

        case let (data, _, _) where data == nil || data?.isEmpty == true:
            return .failure(.emptyResponse)

        case let (.some(data), _, _):
            do {
                return .success(try T(jsonData: data))
            } catch {
                return .failure(.invalidJSON(error))
            }

        default:
            return .failure(.unknown)
        }
    }

    private func fetchResource<T: Decodable>(
        _ resource: HNAPI, completion: @escaping (Result<T, HNAPIError>) -> Void
    ) {
        let resourceUrl = resource.path
        let dataTask = urlSession.dataTask(with: resourceUrl) { data, response, error in
            completion(self.validateResponse(data, response, error))
        }

        dataTask.resume()
    }

    private func fetchItem<T: Item>(
        withId id: Int,
        completion: @escaping (Result<T, HNAPIError>) -> Void
    ) {
        fetchResource(.item(withId: id)) { itemResult in
            completion(itemResult)
        }
    }

    private func fetchItems<T: Item>(
        withIds ids: [Int],
        completion: @escaping ([Result<T, HNAPIError>]) -> Void
    ) {
        let fetchGroup = DispatchGroup()
        var itemsResults = [Result<T, HNAPIError>?](repeating: nil, count: ids.count)

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchItem(withId: id) { (itemResult: Result<T, HNAPIError>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        itemsResults[index] = itemResult
                        fetchGroup.leave()
                    }
                }
            }
        }

        fetchGroup.notify(queue: .global(qos: .userInitiated)) {
            completion(itemsResults.compactMap { $0 })
        }
    }

    private func fetchStoriesIds(
        of type: StoryType, count: Int = 500,
        completion: @escaping (Result<[Int], HNAPIError>) -> Void
    ) {
        fetchResource(.stories(ofType: type)) { (allIdsResult: Result<[Int], HNAPIError>) in
            let idsResult = allIdsResult.map { ids in
                Array(ids.prefix(through: min(count - 1, ids.count)))
            }
            completion(idsResult)
        }
    }

    private func fetchCommentTree(
        _ id: Int,
        completion: @escaping (Result<Comment, HNAPIError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchItem(withId: id) { (commentResult: Result<Comment, HNAPIError>) in
                guard
                    var comment = try? commentResult.get(),  // TODO: map result
                    let kidsIds = comment.kidsIds,
                    !kidsIds.isEmpty
                else {
                    return completion(commentResult)
                }

                let fetchGroup = DispatchGroup()
                var children = [Comment?](repeating: nil, count: kidsIds.count)

                for (index, id) in kidsIds.enumerated() {
                    fetchGroup.enter()
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.fetchCommentTree(id) { child in
                            children[index] = try! child.get()
                            fetchGroup.leave()
                        }
                    }
                }

                fetchGroup.notify(queue: .global(qos: .userInitiated)) {
                    comment.kids = children.compactMap { $0 }
                    completion(.success(comment))
                }
            }
        }
    }
}

// MARK: - HackerNewsAPIClient

extension RESTHNAPIClient: HNAPIClient {
    public var loggedInUser: String? { nil }

    public func fetchStories(
        of type: StoryType, count: Int,
        completion: @escaping ([Result<Story, HNAPIError>]) -> Void
    ) {
        fetchStoriesIds(of: type, count: count) { idsResult in
            guard let ids = try? idsResult.get() else {
                return DispatchQueue.main.async {
                    completion([])
                }
            }

            self.fetchItems(withIds: ids) { storiesResult in
                DispatchQueue.main.async {
                    completion(storiesResult)
                }
            }
        }
    }

    public func fetchComments(
        of story: Story,
        completion: @escaping ([Result<Comment, HNAPIError>]) -> Void
    ) {
        guard let kidsIds = story.kidsIds else {
            return completion([])
        }

        let fetchGroup = DispatchGroup()
        var topLevelComments = [Result<Comment, HNAPIError>?](repeating: nil, count: kidsIds.count)

        for (index, id) in kidsIds.enumerated() {
            fetchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchCommentTree(id) { comment in
                    topLevelComments[index] = comment
                    fetchGroup.leave()
                }
            }
        }

        fetchGroup.notify(queue: .main) {
            completion(topLevelComments.compactMap { $0 })
        }
    }

    public func fetchUser(
        with name: String,
        completion: @escaping (Result<User, HNAPIError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchResource(.user(withName: name)) { (userResult: Result<User, HNAPIError>) in
                DispatchQueue.main.async { completion(userResult) }
            }
        }
    }
}
