//
//  FirebaseAPIClient.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/01/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import SwiftyJSON

// FIXME: error handling (guard / defer ?)
class APIClient : NSObject, NSProgressReporting {

    // MARK: Properties
    dynamic var progress: NSProgress
    private var URLsession: NSURLSession
    private var cache: NSCache // TODO: persist cache to disk, invalidate if necessary

    // MARK: Initializers
    override init() {
        self.progress = NSProgress(totalUnitCount: -1)
        self.URLsession = NSURLSession(
            configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration()
        )
        self.cache = NSCache()
    }

    // MARK: Methods
    func fetchStories(count: Int = 500, source: HackerNewsAPI, completion: (data: [Story]) -> Void) {
        let fetchGroup = dispatch_group_create()
        var stories = [Story]()

        progress = NSProgress(totalUnitCount: -1)

        dispatch_group_enter(fetchGroup)
        fetchData(source.path) { data, error in
            if let storiesData = data {
                let storiesIds = JSON(data: storiesData)
                    .arrayValue
                    .map({ $0.intValue })
                    .prefix(count)

                self.progress.totalUnitCount = Int64(storiesIds.count)

                for id in storiesIds {
                    if let cachedStory = self.cache.objectForKey(id) as? Story {
                        stories.append(cachedStory)
                        self.progress.completedUnitCount += 1
                    } else {
                        dispatch_group_enter(fetchGroup)
                        self.fetchData(HackerNewsAPI.Item(id).path) { data, error in
                            if let storyData = data,
                                story = Story(json: JSON(data: storyData)) {
                                    stories.append(story)
                                    self.cache.setObject(story, forKey: id)
                                    self.progress.completedUnitCount += 1
                                    dispatch_group_leave(fetchGroup)
                                }
                        }
                    }
                }
            }
            dispatch_group_leave(fetchGroup)
        }

        dispatch_group_notify(fetchGroup, dispatch_get_main_queue()) {

            switch (source) {

                case .NewStories:
                stories.sortInPlace({ (s1, s2) -> Bool in
                    return s1.time.compare(s2.time) == NSComparisonResult.OrderedDescending
                })
                break

                case .TopStories:
                stories.sortInPlace({ (s1, s2) -> Bool in
                    return s1.rank > s2.rank
                })

                case _: break
            }

            completion(data: stories)
        }
    }

    func fetchComments(ids: [Int], completion: (data: [Comment]) -> Void) {
        let fetchGroup = dispatch_group_create()
        var comments = [Comment]()

        progress = NSProgress(totalUnitCount: Int64(ids.count))

        for id in ids {
            if let cachedComment = cache.objectForKey(id) as? Comment {
                comments.append(cachedComment)
            } else {
                dispatch_group_enter(fetchGroup)
                fetchData(HackerNewsAPI.Item(id).path) { data, error in
                    if let commentData = data,
                        comment = Comment(json: JSON(data: commentData)) {
                            comments.append(comment)
                            self.cache.setObject(comment, forKey: id)
                            self.progress.completedUnitCount += 1
                            dispatch_group_leave(fetchGroup)
                        }
                }
            }
        }

        dispatch_group_notify(fetchGroup, dispatch_get_main_queue()) {
            completion(data: comments)
        }
    }

    private func fetchData(url: NSURL, completion: (data: NSData?, error: NSError?) -> Void) {
        let task = URLsession.dataTaskWithURL(url) { data, response, error in
            completion(data: data, error: error)
        }

        task.resume()
    }
}