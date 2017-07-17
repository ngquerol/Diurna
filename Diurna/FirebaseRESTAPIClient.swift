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

    private let decoder: JSONDecoder

    private var urlSession: URLSession

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

        decoder = JSONDecoder()
        urlSession = URLSession(configuration: sessionConfig)
    }

    // MARK: Methods
    private func fetchStoriesIds(ofType type: StoryType, count: Int = 500, completion: @escaping (Result<[Int], APIError>) -> Void) {
        getResource(HackerNewsAPI.stories(ofType: type)) { dataResult in
            _ = dataResult.map { data in
                do {
                    completion(.success(try self.decoder.decode([Int].self, from: data)))
                } catch {
                    completion(.failure(APIError.invalidJSON))
                }
            }
        }
    }

    private func fetchStory(withId id: Int, completion: @escaping (Result<Story, APIError>) -> Void) {
        getItem(withId: id) { (storyResult: Result<Story, APIError>) in
            completion(storyResult)
        }
    }

    private func fetchComment(withId id: Int, completion: @escaping (Result<Comment, APIError>) -> Void) {
        getItem(withId: id) { (commentResult: Result<Comment, APIError>) in
            guard let comment = commentResult.value, !comment.kidsIds.isEmpty else {
                completion(commentResult)
                return
            }

            self.getItems(withIds: comment.kidsIds) { (childrenResults: [Result<Comment, APIError>]) in
                comment.kids = childrenResults.flatMap { $0.value }
            }
        }
    }

    private func getResource(_ resource: HackerNewsAPI, completion: @escaping (Result<Data, APIError>) -> Void) {
        let resourceUrl = resource.path.appendingPathExtension("json"),
            dataTask = urlSession.dataTask(with: resourceUrl) { data, response, error in
                let dataResult = self.validateResponse(data, response, error).flatMap { _ in
                    Result(data, failWith: .unknown)
                }

                completion(dataResult)
            }

        dataTask.resume()
    }

    private func getItem<T: Item>(withId id: Int, completion: @escaping (Result<T, APIError>) -> Void) {
        let itemUrl = HackerNewsAPI.item(withId: id).path.appendingPathExtension("json"),
            dataTask = urlSession.dataTask(with: itemUrl) { data, response, error in
                _ = self.validateResponse(data, response, error).map { data in
                    do {
                        completion(.success(try self.decoder.decode(T.self, from: data)))
                    } catch {
                        completion(.failure(APIError.invalidJSON))
                    }
                }
            }

        dataTask.resume()
    }

    private func validateResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<Data, APIError> {
        switch (data, response as? HTTPURLResponse, error) {
        case let (_, _, .some(error)):
            return .failure(.networkError(error as NSError))

        case let (_, .some(response), _) where !(200..<300 ~= response.statusCode):
            return .failure(.invalidHTTPResponse(response))

        case let (data, _, _) where data == nil || data?.count == 0:
            return .failure(.emptyResponse)

        case let (.some(data), _, _):
            return .success(data)

        default:
            return .failure(.unknown)
        }
    }

    private func getItems<T: Item>(withIds ids: [Int], completion: @escaping ([Result<T, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup()
        var itemsResults = [Int: Result<T, APIError>]()

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()
            getItem(withId: id) { (resourceResult: Result<T, APIError>) in
                itemsResults[index] = resourceResult
                fetchGroup.leave()
            }
        }

        completion(itemsResults.sorted { $0.key < $1.key }.map { $0.value })
    }
}

// MARK: - HackerNewsAPIClient

extension FirebaseRESTAPIClient: HackerNewsAPIClient {
    func fetchStories(of type: StoryType, count: Int, completion: @escaping ([Result<Story, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(count))
        var stories = [Int: Result<Story, APIError>]()

        fetchGroup.enter()

        fetchStoriesIds(ofType: type, count: count) { storiesIdsResult in
            guard let storiesIds = storiesIdsResult.value else {
                fetchGroup.leave()
                return
            }

            for (idx, id) in storiesIds.enumerated() {
                fetchGroup.enter()
                self.fetchStory(withId: id) { storyResult in
                    stories[idx] = storyResult
                    progress.completedUnitCount += 1
                    fetchGroup.leave()
                }
            }

            fetchGroup.leave()
        }

        fetchGroup.notify(queue: DispatchQueue.main) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(stories.sorted { $0.key < $1.key }.map { $0.1 })
        }
    }

    func fetchComments(of story: Story, completion: @escaping ([Result<Comment, APIError>]) -> Void) {
        guard !story.kids.isEmpty else {
            completion([])
            return
        }

        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(story.kids.count))
        var topLevelComments = [Int: Result<Comment, APIError>]()

        for (idx, id) in story.kids.enumerated() {
            fetchGroup.enter()
            fetchComment(withId: id) { commentResult in
                topLevelComments[idx] = commentResult
                progress.completedUnitCount += 1
                fetchGroup.leave()
            }
        }

        fetchGroup.notify(queue: DispatchQueue.main) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(topLevelComments.sorted { $0.key < $1.key }.map { $0.value })
        }
    }

    func fetchUser(with name: String, completion: @escaping (Result<User, APIError>) -> Void) {
        getResource(HackerNewsAPI.user(withName: name)) { dataResult in
            _ = dataResult.map { data in
                DispatchQueue.main.async {
                    do {
                        completion(.success(try self.decoder.decode(User.self, from: data)))
                    } catch {
                        completion(.failure(APIError.invalidJSON))
                    }
                }
            }
        }
    }
}
