//
//  MockHNAPIClient.swift
//  HackerNewsAPI
//
//  Created by Nicolas Gaulard-Querol on 30/06/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

public struct MockHNAPIClient {
    private let decoder: JSONDecoder

    public init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
    }

    private func loadTestData<T: Decodable>(from filename: String) -> T {
        guard
            let file = Bundle.main.url(forResource: filename, withExtension: "json")
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }

        let data: Data

        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle: \(error)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as \(T.self): \(error)")
        }
    }
}

// MARK: - HNAPIClient

extension MockHNAPIClient: HNAPIClient {
    public var requestTimeout: TimeInterval {
        get { .infinity }
        set {}
    }

    public var loggedInUser: String? { nil }

    public func fetchStories(
        of type: StoryType, count: Int, completion: @escaping HNAPIResultsCallback<Story>
    ) {
        let stories: [Story] = loadTestData(from: "\(type.rawValue.lowercased())_stories")

        completion(stories.prefix(count).map { .success($0) })
    }

    public func fetchComments(of story: Story, completion: @escaping HNAPIResultsCallback<Comment>)
    {
        guard let kids = story.kids else { return completion([]) }

        completion(kids.map { .success($0) })
    }

    public func fetchUser(with _: String, completion: @escaping HNAPIResultCallback<User>) {
        let user: User = loadTestData(from: "user")

        completion(.success(user))
    }
}
