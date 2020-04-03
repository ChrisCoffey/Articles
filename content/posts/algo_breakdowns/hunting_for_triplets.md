---
title: "Hunting for Triplets"
date: 2020-03-03T06:38:25-05:00
draft: false
tags:
    - algorithm
    - interview
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Finding Geometric Triplets

This was a fun problem.
Implementing something that worked was simple, but finding the correct solution took a change in perspective and deeper insight into the problem.

### The Problem

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

Having said that, grouping by value doesn't change the need to perform an *O(n^3)* algorithm at some point.
Instead of operating on the entire input array, the *n* in this version should be *1/k*, where *k* is the number of distinct values in the input.
But, once the grouping completes and a potential triplet is found, determining the valid indices still consists of three nested loops.

Half an hour into the problem, I had an algorithm:

```haskell
-- O(nlog(n))
arrValueIndexes :: [Integer] -> M.Map Integer [Integer]
arrValueIndexes arr = let
    withIndexes = Data.List.zip arr [0..]
    raw = Data.List.foldl' accumulate M.empty withIndexes
    in Data.List.sort <$> raw
    where
        accumulate acc (x,idx) = M.insertWith (<>) x [idx] acc

countTriplets :: [Integer] -> Integer -> Integer
countTriplets arr r =
    M.foldlWithKey' accumulate 0 arrLookup
    where
        arrLookup = arrValueIndexes arr

        accumulate :: Integer -> Integer -> [Integer] -> Integer
        accumulate acc x indexes =
            case (M.lookup (x*r) arrLookup, M.lookup (x*r*r) arrLookup) of
                (Nothing, _) -> acc
                (_, Nothing) -> acc
                (Just bs, Just cs) -> acc + distinctTriples indexes bs cs

        -- This is O(n^3)
        distinctTriples :: [Integer] -> [Integer] -> [Integer] -> Integer
        distinctTriples [] _ _ = 0
        distinctTriples _ [] _ = 0
        distinctTriples _ _ [] = 0
        distinctTriples (a:as) (b:bs) (c:cs)
            | a < b && b < c = 1 + distinctTriples (a:as) bs (c:c)
            | a >= b = distinctTriples as (b:bs) (c:cs)
            | b >= c = distinctTriples (a:as) (b:bs) cs
```

The algorithm works fine for most inputs, but if the same values appear hundreds of times its performance craters.
The *O(n^3)* portion of the algorithm - `distinctTriples` - dominates the runtime.
Thankfully, the test cases for this problem contained several "pathological" inputs that triggered exactly this behavior, so my solution above only passed 75% of the test cases.

I knew the issue was the performance of the algorithm, but I wasn't sure how to improve it enough to pass all of the cases.
By this point there were about 25 minute left on the clock, so I started quickly trying to optimize my code.

My first idea was to memoize calls to `distinctTriples`.
Doing this has huge benefits for repeated calls for the same values, but how often does that actually occur?
Thinking about this, I realized that memoizing `distinctTriples` in its current form actually wouldn't be particularly useful.
All of the indices in `as` are unique, so even if each result is cached, it will never again be looked up.
This got me considering how to reduce the number of loops overall, and after about 10 minutes I adapted `distinctTriples`.

```haskell
type Memo = Map Integer -> Integer

distinctTriples :: [Integer] -> [Integer] -> [Integer] -> State Memo Integer
distinctTriples [] _ _ = pure 0
distinctTriples _ [] _ = pure 0
distinctTriples _ _ [] = pure 0
distinctTriples (a:as) (b:bs) (c:cs)
    | a < b && b < c = do
        memo <- get
        let mval = b `lookup` memo
        val <- case mval of
                Nothing -> do
                    let vc = validCombinations (b:bs) (c:cs)
                    put $ insert b vc memo
                    pure vc
                Just v ->
                    pure v
        pure $ 1 + (length as * val) + distinctTriples as (b:bs) (c:cs)
    | a >= b = distinctTriples as (b:bs) (c:cs)
    | b >= c = distinctTriples (a:as) (b:bs) cs


validCombinations :: [Integer] -> [Integer] -> Integer
validCombinations [] rest = length rest
validCombinations _ [] = 0
validCombinations (x:xs) (y:ys)
    | x < y = 1 + validCombinations xs (y:ys)
    | otherwise = validCombinations (x:xs) ys
```

Yikes, the code is much more complex now!
Previously we had three simple nested loops, but now there's a `State` monad memoizing calls to `validCombinations`, not to mention `validCombinations` itself.
In aiming to reduce the runtime over the preprocessed data, I applied some of the standard optimizations.
Cache the results of expensive computations.
Try to reduce unnecessary work.

Unfortunately, the solution was still far too slow even with these small optimizations.
When applying the memoization to real inputs, it turned out there were not enough duplicated `validCombinations` checks to dramatically reduce the workload.
On one test input with 100k elements spread evenly across only 10 values, these optimizations removed about a million lookups.
But that was from a base of about 10 billion calls, so not a meaningful change.

After this effort, I only had a few minutes left and was wracking my brain for some other way to optimize the pre-processed input.
At no point did I step back and re-evaluate whether preprocessing was worth the effort.
That means I certainly wasn't trying to devise a single pass algorithm or anything like that.
And so, still with only a 75% pass rate, my time elapsed on the challenge.

## A scalable solution

Preprocessing the input into groups of indices then walking through all three sets hunting for valid triplets didn't work.
Could I have searched through the triplets more effectively?
Or is there a better way?

Unfortunately, there isn't a vastly more efficient means of checking the indices meet the `a < b && b < c` constraint.
The traversal of `c` can be skipped when `b < c` and the length of the remaining elements in `cs` used instead, thanks to having the input sorted.
Even with that improvement the algorithm must visit all values of `as`, all values of `bs`, and all values of `cs` except for those greater than the final value of `bs`.
Keep in mind that this portion of the algorithm begins to dominate the runtime once the same value appears several hundred times in the input.

##### An O(n) solution

The dreaded O(n^3) runtime can be avoided by thinking about the problem from a different direction and focusing in only on the goal itself.
The key to this solution is to recall and focus in on the result only wanting the count, rather than the ability to actually return any particular triplet.
This means it is okay - perhaps even advantageous - to discard information to achieve greater speed.

What information could easily be discarded?
The indices of course!
The flawed solution narrowed in on preprocessing to group by value, but it turns out that was an algorithmic dead-end.
Performing the grouping step forces the algorithm to later pay that dreadful cubic cost to traverse the indexes.
So, instead of preserving all of the indexes, what if only the number of possible triplets were preserved?

To preserve only the number of possible triplets breaks down into three sub problems.
First the algorithm needs to keep track of how many times each value `a` is seen.
Next, it must account for the number of valid pairs `a` participates in.
Finally, it needs to track the number of triples formed with `a`.

The big leap here is realizing that as the list is traversed, `a` will play multiple roles.
Each value in the input list can obviously always form the first vale in a triplet, so the algorithm must track each time `a` is seen.
But `a` can also form the middle value in a triplet, and the point at which it appears determines how many possible first values should be tracked.
This is because a left-to-right traversal guarantees all of the indexes are processed in-order, so the number of times `a/r` has been seen before  this instance of `a` must all form valid initial values in a triplet.
Finally, `a` may also be the last value in a triplet.
When this occurs, the number of seen triplets can be incremented by the number of times `a/r` forms a valid middle value in a triplet.
Its not trivial, so take a few minutes to work through an example or two, and remember that the key is that `a` plays multiple roles each and every time it appears in the input.

This is the correct implementation with comments.

```haskell
countTriplets' ::
    [Integer]
    -> Integer
    -> Integer
countTriplets' ls r = let
    (_ , _, count) = Data.List.foldl' accumulate (M.empty, M.empty, 0) ls
    in count
    where
        accumulate :: (Memo, Memo, Integer) -> Integer -> (Memo, Memo, Integer)
        accumulate (singles, pairs, count) n
            -- If `n` isn't evenly divisible by `r` then it certainly can't form a second or third element
            -- in a geometric triple. Remember that we saw it, but only as a possible first element
            | n `mod` r /= 0 = (singles', pairs, count)

            | otherwise = let
                -- This increments the number of times `n` can be the middle element in a
                -- triplet. If this is the first time `n` appears, then this is a no-op
                pairs' = M.insertWith (+) n (M.findWithDefault 0 key singles) pairs

                -- If `n/r` (aka `key`) has appeared as a middle element before, then this
                -- appearnace of `n` makes it a valid triplet. increment the total triplet
                -- count by the number of times `n\r` has been a middle element.
                count' = count + M.findWithDefault 0 key pairs
                in (singles', pairs', count')
            where
                key = n `div` r
                singles' = M.insertWith (+) n 1 singles
```

Finally understanding this solution was intensely gratifying.
Its not trivial, and it taught me an important lesson about focusing on exactly what a question asks for.
