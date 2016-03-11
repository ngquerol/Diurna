//
//  FirebaseAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import SwiftyJSON

/// All that is needed to get data from the chosen Hacker News API.
/// TODO: Error Handling 😜
class APIClient: NSObject {

    // MARK: Properties
    static let sharedInstance = APIClient()
    private var URLSession: NSURLSession
    private var cache: NSCache

    // MARK: Initializers
    private override init() {
        self.URLSession = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration()
        )
        self.cache = NSCache()
    }

    // MARK: Methods
    func fetchStories(count: Int = 500, source: HackerNewsAPI, completion: (data: [Story]) -> Void) {
        let fetchGroup = dispatch_group_create(),
            progress = NSProgress(totalUnitCount: Int64(count))
        var stories = [Story]()

        dispatch_group_enter(fetchGroup)
        fetchStoriesIds(source, count: count) { storiesIds in
            for id in storiesIds {
                if let cachedStory = self.cache.objectForKey(id) as? Story {
                    stories.append(cachedStory)
                } else {
                    dispatch_group_enter(fetchGroup)
                    self.fetchData(HackerNewsAPI.Item(id).path) { data, error in
                        if let storyData = data,
                            story = Story(json: JSON(data: storyData)) {
                                stories.append(story)
                                self.cache.setObject(story, forKey: id)
                                progress.completedUnitCount += 1
                                dispatch_group_leave(fetchGroup)
                        }
                    }
                }
            }
            dispatch_group_leave(fetchGroup)
        }

        dispatch_group_notify(fetchGroup, dispatch_get_main_queue()) {
            self.sortStories(&stories, source: source)
            completion(data: stories)
        }
    }

    func fetchStoriesIds(source: HackerNewsAPI, count: Int = 500, completion: ([Int]) -> Void) {
        fetchData(source.path) { data, error in
            if let storiesData = data {
                let storiesIds = JSON(data: storiesData)
                    .arrayValue
                    .prefix(count)
                    .reverse()
                    .map { $0.intValue }

                completion(storiesIds)
            }
        }
    }

    func sortStories(inout stories: [Story], source: HackerNewsAPI) {
        switch source {

        case .NewStories:
            stories.sortInPlace { (s1, s2) -> Bool in
                return s1.time.compare(s2.time) == NSComparisonResult.OrderedDescending
            }

        case .TopStories:
            stories.sortInPlace { (s1, s2) -> Bool in
                return s1.rank > s2.rank
            }

        case _: break
        }
    }

    func fetchComments(story: Story, completion: (data: [Comment]) -> Void) {
        let fetchGroup = dispatch_group_create(),
            progress = NSProgress(totalUnitCount: Int64(story.kids.count))
        var comments = [Comment]()

        for id in story.kids {
            dispatch_group_enter(fetchGroup)
            fetchComment(id) { comment in
                comments.append(comment)
                progress.completedUnitCount += 1
                dispatch_group_leave(fetchGroup)
            }
        }

        dispatch_group_notify(fetchGroup, dispatch_get_main_queue()) {
            progress.completedUnitCount = progress.totalUnitCount
            completion(data: comments)
        }
    }

    private func fetchComment(id: Int, completion: (data: Comment) -> Void) {
        if let cachedComment = self.cache.objectForKey(id) as? Comment {
            completion(data: cachedComment)
        } else {
            fetchData(HackerNewsAPI.Item(id).path) { data, error in
                if let commentData = data, comment = Comment(json: JSON(data: commentData)) {
                    let fetchGroup = dispatch_group_create()

                    for id in comment.kidsIds {
                        dispatch_group_enter(fetchGroup)
                        self.fetchComment(id) { childComment in
                            comment.kids.append(childComment)
                            dispatch_group_leave(fetchGroup)
                        }
                    }

                    dispatch_group_notify(fetchGroup, dispatch_get_main_queue()) {
                        self.cache.setObject(comment, forKey: id)
                        completion(data: comment)
                    }
                }
            }
        }
    }

    func fetchUser(id: String, completion: (data: User) -> Void) {
        fetchData(HackerNewsAPI.User(id).path) { data, error in
            if let userData = data, user = User(json: JSON(data: userData)) {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(data: user)
                }
            }
        }
    }

    private func fetchData(url: NSURL, completion: (data: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let dataTask = URLSession.dataTaskWithURL(url) { data, response, error in
            completion(data: data, error: error)
        }
        dataTask.resume()
        return dataTask
    }
}
