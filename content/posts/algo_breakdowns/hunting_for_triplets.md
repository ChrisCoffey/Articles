---
title: "Hunting for Triplets"
date: 2020-03-03T06:38:25-05:00
draft: true
categories:
    - algorithm
    - interview
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Finding Geometric Triplets

This was a fun problem.
Implementing something that worked was simple, but finding the correct solution took a change in perspective and deeper insight into the problem.

#### The Problem

This weeks problem comes from [HackerRank](https://www.hackerrank.com/challenges/count-triplets-1).
It asks us to find all the triplets from a list of integers that form a `1:r:r^2` ratio, given a coefficient `r`.
As an example, `[1,3,9,27]` has two triplets that form a `1:r:r^2` ratio with *3* as the coefficient: `(1,3,9)` and `(3,9,27)`.
The problem has an additional wrinkle to make it more interesting.
Triples like `(a,b,c)` must have `index(a) < index(b) < index(c)`, where `index()` represents the index in the original list the value occurs at.

The input isn't sorted, and there may be duplicates in the input.

#### The test cases

I'll call all of the coefficient's `r` in these test cases and any following examples.

1. **r**=`2`
   `[1, 2, 2, 4]`
   **result**=`2`
2. **r**=`3`
   `[1, 3, 9, 9, 27, 81]`
   **result**=`6`
3. **r**=`5`
   `[1, 5, 5, 25, 125]`
   **result**=`4`

#### One hour attempt

This problem breaks down into several very similar sub-problems.
First, confirm that the numbers in a triplet are a geometric sequence of `(a, a*r, a*r*r)`.
That in turn requires finding three numbers from the input list.
The second main sub-problem is ensuring that the indices for each triplet are increasing.
That means indices either need to be preserved when working with the array, or the array should be processed linearly.
Establishing these smaller problems makes finding a brute-force solution trivial.

The sub-problems above suggest that we can find the answer using three loops, one for `a`, one for `a*r`, and one for `a*r*r`.
The solution also needs an in-order traversal from either the start or end of the list.
For simplicity's sake, starting from the head of the list for each of our three loops makes sense.
Ensuring the ordered-index constraint is easy if we only ever pass the remaining tail of the list to sub-loops.
The result is this lovely *O(n^3)* algorithm

```haskell
countTriplets :: [Int] -> Int -> Int
countTriplets [] _ = 0
countTriplets (x:xs) r = let
    a = r*x
    score = findPossibleMatch a xs
    in score + countTriplets xs r
    where
        findPossibleMatch _ [] = 0
        findPossibleMatch n (i:rest) =
            | n == i = findMatch (n*r) rest
            | otherwise = findPossibleMatch n rest

        findMatch _ [] = 0
        findMatch n (i:rest)
            | n == i = 1 + findMatch n rest
            | otherwise = findMatch n rest
```

Now, an O(n^3) algorithm isn't something to be proud of for this problem, but spending less than 10 minutes to gain a clear understanding of the problem is always worth it.

With 50 minutes remaining, I moved on to finding a more efficient algorithm.
I immediately began thinking about preprocessing the input array, perhaps influenced by the elegant solution to [last week's problem](posts/algo_breakdowns/special_strings)?
Transforming the input array into a map of `value -> [index]` means one of the loops can effectively be ignored.
There are still three loops, but after grouping indices by the value they hold, one of two states of the world will exist.
First, if there were few unique values that occur many times in the input, preprocessing creates a map with few keys and long value lists.
Alternatively, there may have been many unique values in the array but few occurrences per value, in which case the map will have many keys and short value lists.
Those two states depict the extremes on a spectrum, but in either one we've dramatically shortened either the inner or outer loop.
This *should* give us something in the *O(nlog(n))* range


#### A scalable solution
