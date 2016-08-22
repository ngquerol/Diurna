#!/usr/bin/env python

import codecs
import json
import requests
import grequests

api_version = 0
api_base_url = "https://hacker-news.firebaseio.com/v{}/".format(api_version)
api_item_url = "{}item/".format(api_base_url)

stories_types = ["best", "new", "job", "show", "ask", "top"]
max_stories_count = 100


def append_decorator(func, parent, index):
    def append_wrapper(*args, **kwargs):
        kwargs["parent"] = parent
        kwargs["index"] = index
        return func(*args, **kwargs)
    return append_wrapper


def append_comment(response, **kwargs):
    parent = kwargs["parent"]
    index = kwargs["index"]
    comment = response.json()

    parent["kids"][index] = comment

    if "kids" in comment:
        append_comments(comment)


def append_comments(parent):
    if "kids" in parent:
        pool = grequests.Pool(100)

        for i, kid_id in enumerate(parent["kids"]):
            kid_url = "{}{}.json".format(api_item_url, kid_id)
            request = grequests.get(kid_url, hooks={
                "response": append_decorator(append_comment, parent, i)
            })
            grequests.send(request, pool)

        pool.join()


def get_stories(story_type):
    api_story_url = "{}{}stories.json".format(api_base_url, story_type)
    stories_ids = requests.get(api_story_url).json()[0:max_stories_count]
    stories_requests = (grequests.get("{}{}.json".format(api_item_url, s))
                        for s in stories_ids)
    stories = [r.json() for r in grequests.map(stories_requests)]

    return stories


if __name__ == "__main__":
    for story_type in stories_types:
        print("Fetching up to {} {} stories... ".format(
            max_stories_count, story_type)
        )

        stories_filename = "{}stories.json".format(story_type)
        stories = get_stories(story_type)

        print("Done.")
        print("Fetching {} stories comments... ".format(story_type))

        for story in stories:
            append_comments(story)

        print("Done.")

        with codecs.open(stories_filename, "w+", "utf-8") as f:
            f.write(json.dumps(stories))

    print("All done.")
