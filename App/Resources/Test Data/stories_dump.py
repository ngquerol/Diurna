#!/usr/bin/env python3

import aiohttp
import asyncio

import json

api_baseurl = "https://hacker-news.firebaseio.com/v0"
categories = ["ask", "best", "job", "new", "show", "top"]
worker_count = 10
stories_count = 10


# NOTE: asyncio.gather orders the result values the same way as the input
#       awaitables


class ProgressState:
    def __init__(self, category, total):
        self.category = category
        self.total = total
        self.done = 0
        self.output = []

    def story_done(self, item):
        self.done = self.done + 1
        self.output.append(item)

        print(
            f'Fetching "{self.category}" stories... [{self.done}/{self.total}]',
            end="\r",
        )

        if self.done == self.total:
            print()


async def fetch(session, url):
    async with session.get(url) as response:
        return await response.json()


async def fetch_stories_ids(session, category):
    return await fetch(session, f"{api_baseurl}/{category}stories.json")


async def fetch_item(session, id):
    return await fetch(session, f"{api_baseurl}/item/{id}.json")


async def worker(session, queue, shared_state):
    while True:
        story = await fetch_item(session, await queue.get())
        stack = [story]

        while stack:
            parent = stack.pop()

            if not parent or "kids" not in parent:
                continue

            kids_tasks = [fetch_item(session, id) for id in parent["kids"]]
            kids = await asyncio.gather(*kids_tasks)
            parent["_kids"] = [kid for kid in kids if kid]

            stack.extend(parent["_kids"])

        shared_state.story_done(story)

        queue.task_done()


async def fetch_stories(category):
    async with aiohttp.ClientSession() as session:
        all_ids = await fetch_stories_ids(session, category)
        ids = all_ids[:stories_count]

        work_queue = asyncio.Queue()

        for id in ids:
            work_queue.put_nowait(id)

        tasks = []
        shared_state = ProgressState(category, len(ids))

        for _ in range(worker_count):
            task = asyncio.create_task(worker(session, work_queue, shared_state))
            tasks.append(task)

        await work_queue.join()

        for task in tasks:
            task.cancel()

        await asyncio.gather(*tasks, return_exceptions=True)

        return shared_state.output


async def main():
    for category in categories:
        with open(f"{category}_stories.json", "w", encoding="utf8") as f:
            json.dump(await fetch_stories(category), f, indent=2)


if __name__ == "__main__":
    asyncio.run(main())
