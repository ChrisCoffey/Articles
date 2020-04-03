---
title: "Hunting for a match"
date: 2020-03-31T06:58:17-04:00
draft: false
tags:
    - algorithm
    - interview
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Hunting for a match

With all the changes and a new schedule for my toddler its been difficult to find the time to work on these challenges
In fact, this is the first problem I'm attempting under "lockdown".
Its nice to be getting back to drilling on these problems, even if this one felt much easier than the others.

You can find the problem on [HackerRank](https://www.hackerrank.com/challenges/ctci-ice-cream-parlor/problem).

### The Problem

Given a random number `m` between 0 and 1,000,000,000 and long list of numbers, find the first pair of numbers `a` & `b` where `a + b = m`.
"First" is defined as starting from the left-hand side of the input list and working towards the right (i.e. typical array/ linked-list order).
Return the indexes of `a` and `b`.

There may be duplicate values in the list, so be sure to return the *first* match.
Oh, and in a weird twist, the indexes all start at 1 rather than 0...

#### The test cases

**target**: 4, **list**: 1 4 5 3 2, **answer**: 1 4

**target**: 4, **list**: 2 2 4 3, **answer**: 1 2

#### One hour attempt

There weren't many constraints to help us in this problem, but there were more than enough.
The only constraint is: return the lowest pair of indexes that sum to `m`

Upon looking at this, I immediately sketched out the following pseudo-algorithm in my notes.
1. Create a reverse index from cost -> index
2. Walk through costs in-order
3. Search for `m - cost` in the index

The "interesting" part of this algorithm is creating the reverse index.
Even then, its not particularly interesting...
The idea is to walk across the list and accumulate the list of indexes that each cost occurs at.

`fromList . map (\(x:xs) -> (fst x, snd x:(snd <$> xs))) . groupBy fst. sortBy fst` is a ponderous one-line way to generate the reverse index.
But let's have a bit more fun and make something efficient.
These problems generally need to handle large inputs under certain time constraints anyways!

```haskell
costIndexes ::
    [Int]
    -> M.IntMap [Int]
costIndexes costs = let
    indexed = zip costs [1..]
    in Data.List.foldl' f M.empty indexed
    where
        f acc x@(cost, i) = M.insertWith (<>) cost [i] acc
```
This is a two-pass version of the index generation algorithm.
It takes advantage of `insertWith` and the ability of `[]` to make any `a` into a `Monoid`.
Adding elements to the end of the list is still really slow if a lot of elements are added because each application of `<>` requires fully traversing the left-hand list - which includes every element previously added.
Anyways, I'm assuming that the input list doesn't have 1000 elements with the same cost.

The rest of the algorithm was trivial to implement:

```haskell
whatFlavors' :: [Int] -> Int -> IO ()
whatFlavors' costs money = do
  let withIndexes = zip costs [1..]
      res = runSearch (costIndexes withIndexes) withIndexes
  System.IO.print $ (show $ fst res) <> (" "::String) <> (show $ snd res)
  where
      searchCosts :: M.Map Int [Int] -> (Int, Int) -> Maybe Int
      searchCosts indexedCosts (cost, i) =

      runSearch :: M.Map Int [Int] -> [(Int, Int)] -> (Int, Int)
      runSearch indexedCosts (x:xs) =
          case searchCosts indexedCosts x of
              Just secondIndex -> (snd x, secondIndex)
              Nothing -> runSearch indexedCosts xs
```
That's it.
Once the reverse index has been constructed, its a simple matter to iterate over the input and find the first cost that adds up to `m`.

All in, this question took about 25 minutes to implement.
Unfortunately, it wasn't fast enough!
A few test cases were timing out.

I looked through my implementation and realized that I could optimize it in a few ways.
First, I tried swapping out the tree-based hashmap implementation from Haskell's `Data.Map` package.
That passed another case, but one persistent case kept failing due to a timeout.

In a normal situation I'd stop and measure my code, but the time pressure from an interview makes that infeasible.
I looked through my code and noticed that I could reduce the amount of work by filtering out costs > `m` after tagging all of the costs with an index.
This resulted in less work for the indexing step, and fewer elements to iterate through in `runSearch`.
Thankfully, this change was sufficient to pass the final test case, although it took two runs.

The optimization work and additional runs took about 20 minutes, so I had a working solution after 45 minutes.
But I wasn't happy about my solution being right on the cusp of timeouts, particularly for such a simple problem.

## A scalable solution

One of the first posts on the problem's discussion thread mentioned they had an `O(n)` solution.
That got me thinking about how to reduce my solution's complexity to a single pass.

It struck me that the preprocessing step was unnecessary.
Instead of performing multiple passes to index all the data in advance and look for `m - cost` in the index, I could build the index as I went.
This has several advantages:
1. Its a single-pass across the data, so much more efficient
2. Its far simpler compared to the reverse index generation

The algorithm is truly as simple as walking along the input array and remembering the costs that have been seen.
I could go on explaining the algorithm, but its easier to show the five lines of code it requires:

```haskell
whatFlavors :: [Int] -> Int -> M.IntMap Int -> Int -> IO ()
whatFlavors [] _ _ _ = System.IO.putStrLn ("boom"::String)
whatFlavors (cost:rest) money acc n =
    case M.lookup cost acc of
        Just i -> System.IO.putStrLn $ show i <> (" "::String) <> show n
        Nothing -> let
            acc' = M.insert (money - cost) n acc
            in whatFlavors rest money acc' (n+1)
```

As you can see, I extended `whatFlavors` with two bits of state, the seen costs & an index counter.
This is the moral equivalent of a `for` loop.
By traversing across all of the data in-order, this satisfies the "first matching pair" constraint.
By keeping an index of everything that has been *seen* rather than *everything*, it avoids doing any unnecessary work.

### Reflections

I gravitate towards solutions that preprocess data.
In some cases this helps me, but in others it makes me blind to other solutions.

Which is the real problem here.
I need to practice backing off of a potential solution and thinking through at least one alternative approach before writing code.
My hope is that by having at least two pseudo-algorithms in my notebook before I start coding I'll have a much better understanding of the problem.
