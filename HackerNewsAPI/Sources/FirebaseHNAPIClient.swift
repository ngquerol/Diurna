//
//  FirebaseHNAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 01/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Firebase
import Foundation

public struct FirebaseHNAPIClient {
    // MARK: Properties

    public var requestTimeout: TimeInterval = 10.0

    private let responsesQueue = DispatchQueue(label: "fr.ngquerol.HackerNewsAPI.ResponsesQueue")

    private let rootReference: DatabaseReference

    // MARK: Initializer

    public init(app: FirebaseApp) {
        rootReference = Database.database(app: app).reference()
    }

    // MARK: Methods

    private func fetchItem<T: Item>(
        withId id: Int, completion: @escaping (Result<T, HNAPIError>) -> Void
    ) {
        let itemRefUrl = HNAPI.item(withId: id).firebasePath,
            itemRef = rootReference.child(itemRefUrl)

        itemRef.observeSingleEvent(of: .value) { snapshot in
            guard let itemData = snapshot.value as? [String: Any] else {
                return completion(.failure(.emptyResponse))
            }

            do {
                completion(.success(try T(jsonDictionary: itemData)))
            } catch {
                completion(.failure(.invalidJSON(error)))
            }
        }
    }

    private func fetchItems<T: Item>(
        withIds ids: [Int], completion: @escaping ([Result<T, HNAPIError>]) -> Void
    ) {
        let fetchGroup = DispatchGroup()
        var itemsResults = [Result<T, HNAPIError>?](repeating: nil, count: ids.count)

        for (index, id) in ids.enumerated() {
            fetchGroup.enter()

            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchItem(withId: id) { (itemResult: Result<T, HNAPIError>) in
                    itemsResults[index] = itemResult
                    fetchGroup.leave()
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
        let storiesIdsRefUrl = HNAPI.stories(ofType: type).firebasePath,
            storiesIdsRef = rootReference.child(storiesIdsRefUrl)

        DispatchQueue.global(qos: .userInitiated).async {
            storiesIdsRef
                .queryLimited(toFirst: UInt(count))
                .observeSingleEvent(of: .value) { snapshot in
                    if let storiesIds = snapshot.value as? [UInt] {
                        completion(.success(storiesIds.map { Int($0) }))
                    } else {
                        completion(.failure(.unknown))
                    }
                }
        }
    }

    private func fetchCommentTree(
        _ id: Int, completion: @escaping (Result<Comment, HNAPIError>) -> Void
    ) {
        fetchItem(withId: id) { (commentResult: Result<Comment, HNAPIError>) in
            guard
                var comment = try? commentResult.get(),
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
                        // TODO: log/present error msg (status indicator ?
                        children[index] = try? child.get()
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

// MARK: - HackerNewsAPIClient

extension FirebaseHNAPIClient: HNAPIClient {
    public func fetchStories(
        of type: StoryType, count: Int,
        completion: @escaping ([Result<Story, HNAPIError>]) -> Void
    ) {
        let timeout = Timer.scheduledTimer(withTimeInterval: requestTimeout, repeats: false) { _ in
            // TODO: cancel Firebase request, extract timeout mechanism to a wrapper func
            print("Request timed out!")
            return completion([.failure(.requestTimedOut)])
        }

        fetchStoriesIds(of: type, count: count) { idsResult in
            _ = idsResult.map { ids in
                self.fetchItems(withIds: ids) { (storiesResults: [Result<Story, HNAPIError>]) in
                    timeout.invalidate()

                    DispatchQueue.main.async {
                        completion(storiesResults)
                    }
                }
            }
        }
    }

    public func fetchComments(
        of story: Story, completion: @escaping ([Result<Comment, HNAPIError>]) -> Void
    ) {
        guard let kids = story.kidsIds else {
            return completion([])
        }

        let fetchGroup = DispatchGroup()

        let timeout = Timer.scheduledTimer(withTimeInterval: requestTimeout, repeats: false) { _ in
            // TODO: cancel Firebase request
            print("Request timed out!")
            return completion([.failure(.requestTimedOut)])
        }

        var topLevelComments = [Result<Comment, HNAPIError>?](repeating: nil, count: kids.count)

        for (index, id) in kids.enumerated() {
            fetchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.fetchCommentTree(id) { comment in
                    self.responsesQueue.sync {
                        topLevelComments[index] = comment
                    }
                    fetchGroup.leave()
                }
            }
        }

        fetchGroup.notify(queue: .main) {
            timeout.invalidate()
            completion(topLevelComments.compactMap { $0 })
        }
    }

    public func fetchUser(
        with name: String,
        completion: @escaping (Result<User, HNAPIError>) -> Void
    ) {
        let userRefUrl = HNAPI.user(withName: name).firebasePath,
            userRef = rootReference.child(userRefUrl)

        DispatchQueue.global(qos: .userInitiated).async {
            userRef.observeSingleEvent(of: .value) { snapshot in
                guard
                    let userSnapshotData = snapshot.value as? [String: Any]
                else {
                    return DispatchQueue.main.async {
                        completion(.failure(.unknown))
                    }
                }

                DispatchQueue.main.async {
                    do {
                        completion(.success(try User(jsonDictionary: userSnapshotData)))
                    } catch {
                        completion(.failure(.invalidJSON(error)))
                    }
                }
            }
        }
    }
}
