---
title: "Fradulent Activity: when performance really matters"
date: 2020-04-13T06:58:17-04:00
draft: true
tags:
    - algorithm
    - interview
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Finding anomalous activity

Things have been crazy for everyone lately.
Sometimes its nice to retreat to something familiar & focus intently on it.
For me, that's what these challenge problems are.

This week's problem focuses on computing a count using a potentially slow algorithm under some tight performance constraints.
Overall this is my favorite Hacker Rank problem I've done thus far, hopefully you enjoy reading about it.

### The Problem

You're given an array of length `n` and a length `d`.
Compute how many times an element `e` of the input array is >= twice the median of a look-back window starting from `index(e)-1`.
The bounds for each input turned out to be very important for this problem.

The bounds are:
`1 < n <= 200000`
`d <= n`
`1 <= e <= 200`

The median should be the middle item for an odd value of `d`, or the average of the two adjacent middle items for an even `d`.
At least `d` elements must have been seen before the median checks can start.

#### The test cases

Given `[10, 20, 30, 40, 50]` and a window length `d = 3`, the result is one violation of the trailing median constraint.
It occurs at `40`, because the median of `[10, 20, 30]` is 20, and `40 = 2*20`.

Given `[2,3,4,2,3,6,8,4,5]` and a window length of `d=5`, there are two violations.
They occur at `6`, and `8`.

#### One hour attempt

-- Quickly sketch out an algorithm
1: peel off the first `d` elements. Call this list `ls`
2. sort `ls`
3. Find the median
4. Compare it to `head rest`
5. increment a counter if < 2x median
6. Remove the oldest element from `ls`, and add `head rest`
7. Go to 2, and repeat with `rest` until `rest == []`

Attempted this with `Array` in Haskell to get "fast" indexing
But, there are many, many utility functions missing. Namely `sort`
So, I wrote a mergesort for `Data.Array`
It worked, but was too slow for most test cases.

Mergesort guarantees `O(n log-n)`, which is generally a nice property. But a bummer if the elements to drop and add are near the head.
each time `n` ticks along, it costs whatever the sorting algorithm requires, plus the effort to add & remove an element.
Mergesort's firm lower bound actually hurts here.

Moving on to insertion sort. This lets inserting and deleting happen in a single pass.
So, worst case it would require `d` steps to remove the old element and add `head rest`.
That's a nice improvement. But, still too slow. Algorithm is `n*d`
Worst case input is something close to `200k * 20k`, so is there a way to more efficiently track additions and removals?

Also, needed to use a queue to track elements to remove. implemented quick purely-functional queue.

At this point, out of time and very frustrated. Mostly at all of the yak shaving, but also because I couldn't seem to break this problem.

## A scalable solution

At this point, I stepped back and grabbed my copy of CLRS.
I looked through advanced data structures, and considered either an RB tree (or some other self-balancing tree).
But then I took a quick look through the sorting section and stumbled on Counting sort. I feel like I've read about it before, but it certainly entirely escaped from my mind.
Idea is to take advantage of all information you have.

Created frequency table using a Map. No neded to atually reconstruct the output, can just count through the map. But, its complicated & somehow too slow.

Tried switching to faster data structures.
IntMap. too slow
Data.HashTable.IO.BasicHashTable. too slow

At this point, all of these logn for a very small n were somehow too slow. I took a look at the HR environment & saw I should have 5 sec of execution time.
Ruby on the other hand has constant time accss + modify for arrays & 10 seconds of execution time.
Stinging from my failure to solve this in Haskell, I re-implemented the frequency-based algorithm in Ruby & was able to get it working properly after minimal debugging.

### Reflections

- Yak shaving
- Not leveraging every. single. piece. of. information.
    - The bounds on the range of spending turned out to be critically important, because it converted a comparison-based sorting solution to a frequency-based solution, which has linear time.
- Converting purely-functional to imperative and vice versa
    - Array in Ruby offers constant-time access and writes, most purely-functional structures offer log-n best-case. Even something like a mutable hashtable was too slow (check this).
