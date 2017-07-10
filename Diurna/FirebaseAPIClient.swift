//
//  FirebaseAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 01/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation
import Firebase

struct FirebaseAPIClient {

    // MARK: Properties
    static let sharedInstance = FirebaseAPIClient()

    // MARK: Initializers
    private init() {}

    // MARK: Methods
    private func fetchStoriesIds(of type: StoryType, count: Int = 500, completion: @escaping (Result<[Int], APIError>) -> Void) {
        let storiesIdsRefUrl = HackerNewsAPI.stories(ofType: type).path.absoluteString

        guard let storiesIdsRef = Firebase(url: storiesIdsRefUrl) else {
            return completion(.failure(.unknown))
        }

        storiesIdsRef.queryLimited(toFirst: UInt(count)).observeSingleEvent(of: .value) { (idsSnapshot: FDataSnapshot?) in
            if let idsSnapshot = idsSnapshot, let storiesIds = idsSnapshot.value as? [UInt] {
                completion(Result(storiesIds.map { Int($0) }, failWith: .unknown))
            } else {
                completion(.failure(.unknown))
            }
        }
    }

    private func fetchCommentTree(_ id: Int, completion: @escaping (Result<Comment, APIError>) -> Void) {
        fetchItem(withId: id) { (commentResult: Result<Comment, APIError>) in
            guard let comment = commentResult.value, !comment.kidsIds.isEmpty else {
                completion(commentResult)
                return
            }

            let fetchGroup = DispatchGroup(),
                progress = Progress(totalUnitCount: Int64(comment.kidsIds.count))
            var children = [Comment?](repeating: nil, count: comment.kidsIds.count)

            for (index, id) in comment.kidsIds.enumerated() {
                fetchGroup.enter()
                self.fetchCommentTree(id) { child in
                    children[index] = child.value
                    progress.completedUnitCount += 1
                    fetchGroup.leave()
                }
            }

            fetchGroup.notify(queue: DispatchQueue.main) {
                progress.completedUnitCount = progress.totalUnitCount
                comment.kids = children.flatMap { $0 }
                completion(.success(comment))
            }
        }
    }

    private func fetchItem<T: Item>(withId id: Int, completion: @escaping (Result<T, APIError>) -> Void) {
        let itemRefUrl = HackerNewsAPI.item(withId: id).path.absoluteString

        guard let itemRef = Firebase(url: itemRefUrl) else {
            return completion(.failure(.unknown))
        }

        itemRef.observeSingleEvent(of: .value) { (storySnapshot: FDataSnapshot?) in
            guard let itemData = storySnapshot?.value as? [String: Any] else {
                completion(.failure(.invalidJSON))
                return
            }

            completion(Result(T(dictionary: itemData), failWith: .unknown))
        }
    }

    private func fetchItems<T: Item>(withIds ids: [Int], completion: @escaping ([Result<T, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup()
        var itemsResults = [Int: Result<T, APIError>]()

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()
            fetchItem(withId: id) { (itemResult: Result<T, APIError>) in
                itemsResults[index] = itemResult
                fetchGroup.leave()
            }
        }

        fetchGroup.notify(queue: .main) {
            completion(itemsResults.sorted { $0.0 < $1.0 }.map { $0.1 })
        }
    }
}

extension FirebaseAPIClient: HackerNewsAPIClient {

    func fetchStories(of type: StoryType, count: Int, completion: @escaping ([Result<Story, APIError>]) -> Void) {
        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(count))
        var stories = [Int: Result<Story, APIError>]()

        fetchGroup.enter()

        fetchStoriesIds(of: type, count: count) { idsResult in
            guard let ids = idsResult.value else {
                fetchGroup.leave()
                return
            }

            for (idx, id) in ids.enumerated() {
                fetchGroup.enter()
                self.fetchItem(withId: id) { (storyResult: Result<Story, APIError>) in
                    stories[idx] = storyResult
                    progress.completedUnitCount += 1
                    fetchGroup.leave()
                }
            }

            fetchGroup.leave()
        }

        fetchGroup.notify(queue: .main) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(stories.sorted { $0.0 < $1.0 }.map { $0.1 })
        }
    }

    func fetchComments(of story: Story, completion: @escaping ([Result<Comment, APIError>]) -> Void) {
        guard !story.kids.isEmpty else {
            return completion([])
        }

        let fetchGroup = DispatchGroup(),
            progress = Progress(totalUnitCount: Int64(story.kids.count))
        var topLevelComments = [Int: Result<Comment, APIError>]()

        for (index, id) in story.kids.enumerated() {
            fetchGroup.enter()
            fetchCommentTree(id) { comment in
                topLevelComments[index] = comment
                progress.completedUnitCount += 1
                fetchGroup.leave()
            }
        }

        fetchGroup.notify(queue: .main) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(topLevelComments.sorted { $0.0 < $1.0 }.map { $0.1 })
        }
    }

    func fetchUser(with name: String, completion: @escaping (Result<User, APIError>) -> Void) {
        let userRefUrl = HackerNewsAPI.user(withName: name).path.absoluteString

        guard let userRef = Firebase(url: userRefUrl) else {
            return completion(.failure(.unknown))
        }

        userRef.observeSingleEvent(of: .value) { (userSnapshot: FDataSnapshot?) in
            DispatchQueue.main.async {
                if let userSnapshot = userSnapshot, let userSnapshotData = userSnapshot.value as? [String: Any] {
                    completion(Result(User(dictionary: userSnapshotData), failWith: .unknown))
                } else {
                    completion(.failure(.unknown))
                }
            }
        }
    }
}
