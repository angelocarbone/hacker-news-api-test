# Parsing “Ask HN: Who is hiring?” with Python and Hacker News API

Have you heard of [Hacker News](https://news.ycombinator.com/)? It’s a great mini social network dedicated to all things tech. Once a month they post a thread called [“Ask HN: Who is hiring?”](https://news.ycombinator.com/item?id=15824597), where anyone can list their job openings.

With hundreds of comments, it quickly gets overwhelming. Turns out it’s very easy to get the same data via [Hacker News API](https://github.com/HackerNews/API).

For example, hitting [https://hacker-news.firebaseio.com/v0/item/8863.json?print=pretty](https://hacker-news.firebaseio.com/v0/item/8863.json?print=pretty) will return the following:

```json
{
  "by" : "dhouston",
  "descendants" : 71,
  "id" : 8863,
  "kids" : [ 8952, 9224, 8917, 8884, 8887, 8943, 8869, 8958, 9005, 9671, 9067, 8940, 8908, 9055, 8865, 8881, 8872, 8873, 8955, 10403, 8903, 8928, 9125, 8998, 8901, 8902, 8907, 8894, 8878, 8980, 8870, 8934, 8876 ],
  "score" : 111,
  "time" : 1175714200,
  "title" : "My YC app: Dropbox - Throw away your USB drive",
  "type" : "story",
  "url" : "http://www.getdropbox.com/u/2/screencast.html"
}
```

Where `kids` are all of the comments on post specified via id `8863`.

For those following along, I highly recommend using [Jupyter](http://jupyter.org/), which is only a `pip install jupyter` away, or download image from my Docker Hub:

```
$ docker pull angelocarbone/hacker-news-api-test
```


## Step 1. Get the story ID

Story ID is in the URL of the page. For example, URL for `Ask HN: Who is hiring? (December 2017)` is : `https://news.ycombinator.com/item?id=15824597`, so ID is `15824597`.



## Step 2. Get the Post Content

Content of the mains post is retrieved by changing ID in the Hacker News API link, resulting in `https://hacker-news.firebaseio.com/v0/item/15824597.json`.

I created a function to construct the URL and used it to get the data, with the help of [requests](http://docs.python-requests.org/en/master/) module.

```python
import requests

def getItemUrl(id):
    return 'https://hacker-news.firebaseio.com/v0/item/{}.json'.format(str(id))
 
storyID = 15824597
story = requests.get(getItemUrl(storyID)).json()
```

At this point I have the story and a list of IDs of all of the “kids”.



## Step 3. Get all comments

I used a similar process for all of the kids to get their content. The “who is hiring” post had over 600 comments, so I used [tqdm](https://pypi.python.org/pypi/tqdm) module to show me the progress while I waited. I also used [list comprehension](http://www.pythonforbeginners.com/basics/list-comprehensions-in-python) instead of a regular `for` loop.

```python
from tqdm import tqdm

comments = [requests.get(getItemUrl(c)).json() for c in tqdm(story['kids'])]
```

After that I backed up all of the comments as a JSON file, just in case.

```python
import json

with open("who-is-hiring.json", "w") as f:
    json.dump(comments, f)
```



## Step 4. Profit

I only wanted to see jobs close to my home, so I made a new list only containing comments that had “CA” in them. Turned out that some comments were deleted and had no `text`, so I added a check for that as well.

```python
ca = [c for c in comments if "text" in c and "CA" in c['text']]
```

Common way to write location in the comment is like `San Francisco | CA`, so I’ve split every comment text by `CA`. I took the resulting left side and split it by empty space to get all of the words. Finally I took 3 words to the left of CA and combined them back into one sentence, hoping that it would give me a good signal for the location.

I converted the list of locations to a set, in order to remove all duplicates.

```python
locations = []

for c in ca:
    beforeca = c['text'].split("CA")[0]         # Get everything to the left of CA
    loc = " ".join(beforeca.split(" ")[-3:])    # Get 3 words before CA
    locations.append(loc)                       # Save it
    
set(locations)                                  # Remove duplicates
```

I got about 20 locations back. It was easy to look at all and identify a few that made sense for me. I picked out San Mateo and Redwood City.

Finally I wrote all matching comments into an HTML file.

```python
tocheck = ["Redwood City", "San Mateo"]

import codecs

with codecs.open("res.html", "w", encoding="utf-8") as f:       # Need codecs to write utf-8 in Python 2
    for c in comments:
        for check in tocheck:
            if 'text' in c and check in c['text']:              # If desired city
                f.write(c['text'])                              # Save to file
                f.write("<hr/>")                                # Separated by horizontal ruler
```

I opened results in a web browser using generated html file (res.html)

I thought this was pretty handy. Thanks Hacker News!



## Resourses

https://news.ycombinator.com/

https://www.alexkras.com/parse-ask-hn-who-is-hiring-python-and-hacker-news-api/