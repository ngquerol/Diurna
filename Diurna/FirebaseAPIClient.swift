//
//  FirebaseAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 01/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Firebase
import Foundation

struct FirebaseAPIClient {

    // MARK: Properties

    static let sharedInstance = FirebaseAPIClient()

    private let requestsQueue = DispatchQueue(
        label: "fr.ngquerol.Diurna.APIRequestsQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private let responsesQueue = DispatchQueue(
        label: "fr.ngquerol.Diurna.APIResultsQueue",
        qos: .userInitiated
    )

    // MARK: Initializers

    private init() {
        Firebase.defaultConfig().callbackQueue = responsesQueue
    }

    // MARK: Methods

    private func fetchItem<T: Item>(withId id: Int, completion: @escaping (Result<T, APIError>) -> Void) {
        let itemRefUrl = HackerNewsAPI.item(withId: id).path.absoluteString

        guard let itemRef = Firebase(url: itemRefUrl) else {
            return completion(.failure(.clientError("Failed to initialize Firebase reference @ \(itemRefUrl)")))
        }

        itemRef.observeSingleEvent(of: .value) { (storySnapshot: FDataSnapshot?) in
            guard let itemData = storySnapshot?.value as? [String: Any] else {
                return completion(.failure(.invalidJSON))
            }

            completion(Result(T(json: itemData), failWith: .invalidJSON))
        }
    }

    private func fetchItems<T: Item>(withIds ids: [Int], completion: @escaping ([Result<T, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(ids.count))
        var itemsResults = [Result<T, APIError>?](repeating: nil, count: ids.count)

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()
            requestsQueue.async {
                self.fetchItem(withId: id) { (itemResult: Result<T, APIError>) in
                    itemsResults[index] = itemResult
                    progress.completedUnitCount += 1
                    fetchGroup.leave()
                }
            }
        }

        fetchGroup.notify(queue: responsesQueue) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(itemsResults.flatMap { $0 })
        }
    }

    private func fetchStoriesIds(of type: StoryType, count: Int = 500, completion: @escaping (Result<[Int], APIError>) -> Void) {
        let storiesIdsRefUrl = HackerNewsAPI.stories(ofType: type).path.absoluteString

        guard let storiesIdsRef = Firebase(url: storiesIdsRefUrl) else {
            return completion(.failure(.clientError("Failed to initialize Firebase reference @ \(storiesIdsRefUrl)")))
        }

        requestsQueue.async {
            storiesIdsRef
                .queryLimited(toFirst: UInt(count))
                .observeSingleEvent(of: .value) { (idsSnapshot: FDataSnapshot?) in
                    if let idsSnapshot = idsSnapshot, let storiesIds = idsSnapshot.value as? [UInt] {
                        completion(.success(storiesIds.map { Int($0) }))
                    } else {
                        completion(.failure(.invalidJSON))
                    }
                }
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
                    comment.kids = children.flatMap { $0 }
                    completion(.success(comment))
                }
            }
        }
    }
}

// MARK: - HackerNewsAPIClient

extension FirebaseAPIClient: HackerNewsAPIClient {

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
            completion(topLevelComments.flatMap { $0 })
        }
    }

    func fetchUser(with name: String, completion: @escaping (Result<User, APIError>) -> Void) {
        let userRefUrl = HackerNewsAPI.user(withName: name).path.absoluteString

        guard let userRef = Firebase(url: userRefUrl) else {
            return completion(.failure(.clientError("Failed to initialize Firebase reference @ \(userRefUrl)")))
        }

        requestsQueue.async {
            userRef.observeSingleEvent(of: .value) { (userSnapshot: FDataSnapshot?) in
                guard
                    let userSnapshot = userSnapshot,
                    let userSnapshotData = userSnapshot.value as? [String: Any]
                else {
                    return DispatchQueue.main.async {
                        completion(.failure(APIError.emptyResponse))
                    }
                }

                DispatchQueue.main.async {
                    completion(Result(User(json: userSnapshotData), failWith: .invalidJSON))
                }
            }
        }
    }
}
