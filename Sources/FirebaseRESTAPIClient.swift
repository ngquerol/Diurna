//
//  FirebaseRESTAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 11/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

struct FirebaseRESTAPIClient {

    // MARK: Properties

    static let sharedInstance = FirebaseRESTAPIClient()

    private let requestsQueue = DispatchQueue(
        label: "fr.ngquerol.Diurna.APIRequestsQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private let responsesQueue = DispatchQueue(
        label: "fr.ngquerol.Diurna.APIResultsQueue",
        qos: .userInitiated
    )

    private let jsonDecoder = JSONDecoder()

    private var urlSession: URLSession

    // MARK: Initializers

    private init() {
        let sessionConfig = URLSessionConfiguration.default

        sessionConfig.timeoutIntervalForRequest = 10
        sessionConfig.timeoutIntervalForResource = 20
        sessionConfig.httpShouldUsePipelining = true
        sessionConfig.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Accept-Charset": "utf-8",
            "Accept-Encoding": "gzip, deflate",
        ]

        urlSession = URLSession(configuration: sessionConfig)
    }

    private func validateResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<Data, APIError> {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, .some(error)):
            return .failure(.networkError(error as NSError))

        case let (_, .some(response), _) where !(200 ..< 300 ~= response.statusCode):
            return .failure(.invalidHTTPResponse(response))

        case let (data, _, _) where data == nil || data?.count == 0:
            return .failure(.emptyResponse)

        case let (.some(data), _, _):
            return .success(data)

        case _:
            return .failure(.unknown)
        }
    }

    private func getResource(_ resource: HackerNewsAPI, completion: @escaping (Result<Data, APIError>) -> Void) {
        let resourceUrl = resource.path.appendingPathExtension("json"),
            dataTask = urlSession.dataTask(with: resourceUrl) { data, response, error in
                completion(self.validateResponse(data, response, error))
            }

        dataTask.resume()
    }

    private func fetchItem<T: Item>(withId id: Int, completion: @escaping (Result<T, APIError>) -> Void) {
        let itemUrl = HackerNewsAPI.item(withId: id).path.appendingPathExtension("json"),
            dataTask = urlSession.dataTask(with: itemUrl) { data, response, error in
                let itemResult = self.validateResponse(data, response, error).flatMap { data in
                    Result(T(jsonData: data), failWith: .invalidJSON)
                }

                completion(itemResult)
            }

        dataTask.resume()
    }

    private func fetchItems<T: Item>(withIds ids: [Int], completion: @escaping ([Result<T, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(ids.count))
        var itemsResults = [Result<T, APIError>?](repeating: nil, count: ids.count)

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()
            requestsQueue.async {
                self.fetchItem(withId: id) { (itemResult: Result<T, APIError>) in
                    self.responsesQueue.async {
                        itemsResults[index] = itemResult
                        progress.completedUnitCount += 1
                        fetchGroup.leave()
                    }
                }
            }
        }

        fetchGroup.notify(queue: responsesQueue) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(itemsResults.compactMap { $0 })
        }
    }

    private func fetchStoriesIds(of type: StoryType, count: Int = 500, completion: @escaping (Result<[Int], APIError>) -> Void) {
        getResource(HackerNewsAPI.stories(ofType: type)) { dataResult in
            let idsResult = dataResult.flatMap { data in
                Result({ () -> [Int] in
                    let ids = try self.jsonDecoder.decode([Int].self, from: data)
                    return Array(ids.prefix(through: count - 1))
                })
            }

            completion(idsResult)
        }
    }

    private func fetchCommentTree(_ id: Int, completion: @escaping (Result<Comment, APIError>) -> Void) {
        requestsQueue.async {
            self.fetchItem(withId: id) { (commentResult: Result<Comment, APIError>) in
                guard
                    let comment = commentResult.value,
                    let kidsIds = comment.kidsIds,
                    !kidsIds.isEmpty
                else {
                    return completion(commentResult)
                }

                let fetchGroup = DispatchGroup(),
                    progress = Progress(totalUnitCount: Int64(kidsIds.count))
                var children = [Comment?](repeating: nil, count: kidsIds.count)

                for (index, id) in kidsIds.enumerated() {
                    fetchGroup.enter()
                    self.requestsQueue.async {
                        self.fetchCommentTree(id) { child in
                            children[index] = child.value
                            progress.completedUnitCount += 1
                            fetchGroup.leave()
                        }
                    }
                }

                fetchGroup.notify(queue: self.responsesQueue) {
                    progress.completedUnitCount = progress.totalUnitCount
                    comment.kids = children.compactMap { $0 }
                    completion(.success(comment))
                }
            }
        }
    }
}

// MARK: - HackerNewsAPIClient

extension FirebaseRESTAPIClient: HackerNewsAPIClient {

    func fetchStories(of type: StoryType, count: Int, completion: @escaping ([Result<Story, APIError>]) -> Void) {
        let progress = Progress(totalUnitCount: Int64(count))

        fetchStoriesIds(of: type, count: count) { idsResult in
            guard let ids = idsResult.value else {
                return DispatchQueue.main.async {
                    completion([])
                }
            }

            progress.becomeCurrent(withPendingUnitCount: Int64(count))

            self.fetchItems(withIds: ids) { storiesResult in
                DispatchQueue.main.async {
                    completion(storiesResult)
                }
            }
        }
    }

    func fetchComments(of story: Story, completion: @escaping ([Result<Comment, APIError>]) -> Void) {
        guard let kids = story.kids else {
            return completion([])
        }

        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(kids.count))
        var topLevelComments = [Result<Comment, APIError>?](repeating: nil, count: kids.count)

        for (index, id) in kids.enumerated() {
            fetchGroup.enter()
            requestsQueue.async {
                self.fetchCommentTree(id) { comment in
                    topLevelComments[index] = comment
                    progress.completedUnitCount += 1
                    fetchGroup.leave()
                }
            }
        }

        fetchGroup.notify(queue: .main) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(topLevelComments.compactMap { $0 })
        }
    }

    func fetchUser(with name: String, completion: @escaping (Result<User, APIError>) -> Void) {
        requestsQueue.async {
            self.getResource(HackerNewsAPI.user(withName: name)) { dataResult in
                let userResult = dataResult.flatMap {
                    Result(User(jsonData: $0), failWith: APIError.invalidJSON)
                }
                DispatchQueue.main.async { completion(userResult) }
            }
        }
    }
}
