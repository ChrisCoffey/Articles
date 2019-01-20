---
title: "Cuckoo Filters: Part 1"
date: 2019-01-20T16:07:29-04:00
draft: false
tags: ["haskell", "performance", "theory"]
---


### Approximate Set Membership
Several years ago I was hard at work building a near-realtime database of events happening around the world.
This was a classic crawling problem, where I'd need to make sure I'm not checking the same location for events twice, or looking for events hosted by the same person twice.
Initially the team and I were able to get away with using a regular `Set` for this, but as we scaled up to handle millions of sources this approach broke down.
We turned to a classic data structure, the _Bloom Filter_.

Bloom filters are part of a small family of probabilistic (i.e. approximate) data structures that answer very specific problems with far greater efficiency than their standard counterparts.
Specifically, bloom filters allow you to answer whether a certain value is in a set or not, i.e. set membership.
It gains its efficiency by forcing you to phrase the question as "Is **x** definitely not in this set?", so a *yes* means that there is no possible way **x** is in the set, while a *no* means that **x** could possibly be in the set.
At this point, you're probably wondering why this is a useful thing to ask, so lets talk through a couple of classic uses for bloom filters.

Conceived in 1970, bloom filters started appearing during the late 1970s-early '80s as personal computers became a reality.
Machines like the [Altair 8800] (https://en.wikipedia.org/wiki/Altair_8800) or [Apple 2]( https://en.wikipedia.org/wiki/Apple_II_series ) could rarely hold more than 48-64kb of data in memory, so getting a useful word processing program with spell-checking running was quite the challenge.
Using the straightforward approach of precomputing a table with all words stored in it then performing lookups as the user types would entail storing most of the target language in memory.
Using the standard 7-bit ASCII encoding for all 170k words of English, the 5 character average word length meant programmers would have needed 743kb to store English, far beyond their machine's capacity.
Yet programmers at the time were able to fit both word processing software _and_ a spell checker onto an Apple 2 by making a few changes to the naive approach above.
First, they realized that the vast majority of written English uses the same 14k words, so they were able to get a 10x improvement right there.
Second, by accepting a small (1:500 - 1:1000) false positive percentage, they were able to rephrase their question into one that a bloom filter could answer.
By shipping a ~25Kb pre-built bloom filter in the spell checker, they were able to provide an effective spell checker while using only 50% of the available memory.

Another common use for them is tracking sites during a crawl as mentioned earlier.
When crawling, you'll typically conduct a breadth-first search of the available & unknown links.
As new links are discovered, they're added to a queue for processing.
For particularly popular pages there are many incoming links, of which you only want to process a single time.
To avoid storing an in-memory set of the full seen links (i.e. use up lots of memory storing strings), you can use a bloom filter to check if the link has _probably_ already been seen.
By choosing a small (1:10000) chance of duplicates, you're able to efficiently keep track of what you've already seen without paying the additional complexity+performance hit of using external storage (disk, redis, etc...).

If you're not already familiar with them, at this point you're probably asking how bloom filters achieve this kind of space savings.
Basically, they're an array of `m` bits, and an array of `k` hash functions.
When an `insert` occurs, each of the `k` functions is run, producing `k` indices into `m`, all of which are set.
Upon lookup, the same `k` functions are run, and if all `k` bits are set then the element is _probably_ in the set.
I say probably because as you may have noticed, the more elements you insert into the filter the more likely it is that the overlap between elements will result in false positives.
Therefore, bloom filters must be tuned to an expected set size during initialization.
As the load increases, the false positive probability for any given lookup increases as well.
A filter at 100% load (all `m` bits set) will always return `true` when asked if an element is in the set.

### Enter Cuckoo Filters
My previous experience with bloom filters has left me curious about probabilistic data structures & approximate membership queries specifically.
Back in May 2018 I stumbled on a Hacker News thread where someone was talking about an alternative to bloom filters that made different design trade offs.
Called Cuckoo Filters, they answered the same question but provided different asymptotics as they grew.
I'm not going to explain the details of how they work (the [original paper](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf) is very accessible), but its worth providing a high-level summary.

Where a bloom filter relies on `k` different hash functions, a cuckoo filter uses two hash functions and a "fingerprint hash" function.
Instead of setting individual bits in an array, cuckoo filters use the concept of _buckets_ that contain a fixed number of fingerprints.
Fingerprints are generally small, in the 6-8 bit range.  All buckets contain between 0..`b` fingerprints, where `b` is typically between 4 & 6.
As elements are inserted into a cuckoo filter one of the two hash functions is randomly chosen and used to determine the bucket for the element.
The element's fingerprint is computed & added to the bucket.
If the bucket is full, i.e. already contains `b` fingerprints, then a fingerprint is chosen at random and evicted.
The elegance of cuckoo filters is that the two hash functions are invertible, meaning that given the fingerprint & bucket index of an element, the other bucket can be computed.
This makes it possible to move the evicted fingerprint to its "alternative" bucket.
If the alternative bucket is full, then another fingerprint is evicted and the kicking behavior repeats.
This cycle of eviction + migration should have a short-circuit built in that terminates after a set number of evictions occurs in order to prevent infinite loops or excessively slow insertions.

The above behavior means that unlike bloom filters, where insertion always succeeds but the false positive probability rises, cuckoo filters prevent the false positive probability from rising by allowing insertion to fail.
There are a few other key differences from bloom filters as well, namely that you can delete from a cuckoo filter if you're so inclined.
Personally, I've never been in a situation where this is desirable, but I can see it being useful if membership in a set "expires" somehow.

Cuckoo filters stack up nicely against bloom filters performance-wise as well, both in access time & memory footprint per-item. Some in-depth performance metrics are available on page 10 of the Fan paper linked above, which you should absolutely take a look at if you're curious.

### What about a Haskell implementation??
As you may have already gathered, I do most of my work in Haskell these days.
So I wasn't particularly surprised to find that there was not a Haskell cuckoo-filter library available.
This is more of a testament to the kinds of things us Haskellers spend our time on than the complexity of providing a cuckoo filter implementation in haskell, so I decided to give it a shot.
You can find it on Stackage or Hackage under `cuckoo-filter`, and on [Github](https://github.com/ChrisCoffey/cuckoo-filter).

It was a lot of fun authoring an efficient library, which I'll write about next.
