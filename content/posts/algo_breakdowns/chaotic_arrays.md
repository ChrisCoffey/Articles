---
title: "Chaotic arrays"
date: 2020-03-12T06:58:17-04:00
draft: false
tags:
    - algorithm
    - interview
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Unwinding chaotic arrays

I went through this problem back in late February, but with COVID-19 its been difficult find the time for reflection and documenting my attempt.
It felt easier than the other problems, although its of the same level as the others in this series.
Without further preamble, let's get to the problem breakdown.

### The Problem

There is a line of people waiting in line for something.
They're numbered with their place in line.
Anyone in the line is allowed to swap places with the person directly in front of them, but they can only swap at-most two times.
You're given the final state of a line - as an array of integers - and must determine either a) the minimum number of swaps to create this ordering or b) this is an impossible ordering.

#### The test cases

- Given a line with length `5` and final state `[2, 1, 5, 3, 4]`, the minimum number of moves is `3`.
- Given a line with length `5` and final state `[2, 5, 1, 3, 4]`, the queue is in an impossible state.
- Given a line with length `8` and final state `[5, 1, 2, 3, 7, 8, 6, 4]`, the queue is in an impossible state.
- Given a line with length `8` and final state `[1, 2, 5, 3, 7, 8, 6, 4]`, the minimum number of moves is `7`.

#### One hour attempt

I spent the first 5-10 minutes reading through the problem statement.
It breaks down into several smaller problems.

First, determine how many times a given person swapped.
Since the problem states a given person may swap at-most to times, did they swap zero, one, or two times?

Second, determine the total number of swaps for the entire line, given its current state.
This is just iterating across the entire line and checking how many times each individual swapped.

With 50 minutes left on the clock and a basic understanding of the problem, I sat down to start writing some code.

For some reason, my initial draft was unfocused and impractical.
I spent a few minutes thinking through just how much work would be involved in actually searching the entire move tree from the initial line state to what's provided in the question.
Once the line is more than a dozen or so people, that becomes wildly impractical since the runtime is a bit less than factorial.

Putting a simple brute-force search on the shelf and chuckling to myself, it was time to fine a more direct solution.
I was looking at the data and playing around with a few lines in my notebook when I realized that I could take advantage of the constraints on the problem.
That sounds obvious in hindsight, but it somehow took me ~20 minutes to notice.

The only interesting constraint imposed by the problem is that a person may only pass two individuals in front of them.
When they pass someone, that means that a smaller number will appear behind them.
So, the number of passes a person performs can be found by determining how many values less than their own occur behind them in the line.
Let's take a look at this idea in code:

``` haskell
numLessThan :: Int -> Int -> [Int] -> Int
numLessThan _ 2 _ =  2
numLessThan x n (a:as)
    | a < x = numLessThan x (n+1) as
    | otherwise = numLessThan x n as
numLessThan _ n [] = n
```
For a given list, `numLessThan` simply loops through the list and determines how many values less than `x` occur in the list.
This is exactly the operation described above.
Its great when the function at the heart of a solution is so straightforward!

Now to integrate `numLessThan` into the full solution and determine the `n` for each index in the input line.
That is as simple as adding an outer traversal and accumulating the results:

``` haskell
lessThanBehind :: [Int] -> Int
lessThanBehind [] = 0
lessThanBehind (x:rest) =
    numLessThan 0 rest + lessThanBehind rest
    where
        numLessThan :: Int -> [Int] -> Int
        numLessThan n (a:as)
            | a < x = numLessThan (n+1)  as
            | otherwise = numLessThan n  as
        numLessThan n [] = n
```
If you're paying attention, you've probably noticed that this solution is horribly inefficient for large inputs.
Indeed, because `numLessThan` as implemented iterates across the *entire* `rest` list, for an input of 10k, this means performing 9,999, then 9,998, etc... comparisons.
I haven't bothered looking up or calculating exactly what that is, but its somewhere around `O(log n * n^2)`.
I.e. a very bad runtime.

I knew I'd need to solve this, so with 25 minutes left I tacked in an arbitrary cost ceiling on `lessThanBehind`.
My assumption was that while a degenerate case could move the first value to the very back of the input line, if the inputs were randomly generated then this was extremely unlikely.
So, I tacked on a maximum cost of 100 comparisons per `n`, leaving `numLessThan` looking like this:
```haskell
lessThanBehind :: [Int] -> Int
lessThanBehind [] = 0
lessThanBehind (x:rest) =
    numLessThan 0 rest + lessThanBehind rest
    where
        numLessThan :: Int -> Int -> [Int] -> Int
        numLessThan 2 _ _ =  2
        numLessThan n 100 _ = n
        numLessThan n counter (a:as)
            | a < x = numLessThan (n+1) (counter+1) as
            | otherwise = numLessThan n (counter+1) as
        numLessThan n _ [] = n
```
Introducing cost tracking on `lessThanBehind` cuts this from an exponential to a linear time algorithm - albeit with a large constant factor.
As mentioned earlier, because the constant factor is hardcoded and a heuristic, there are many inputs that produce an incorrect result.
All it takes is passing the same person in line more than 100 times.

And so, with about 15 minutes left and a mostly-working algorithm in place, it was time to address the final part of the problem - determining if an input is an impossible state.
States become impossible when a certain individual passes more than two others.
Finding impossible states is a simple extension of the `numLessThan` function, at least in principle.

The idea behind `invalidInput` is to match up each value in the input list with the index it occurs at.
Only being able to pass two individuals means the furthest forward a given `n` should appear is at index `n-1`, assuming a 0-indexed array.
So, the validity check is simply:
```haskell
invalidInput :: [(Int, Int)] -> Bool
invalidInput =
    any ( (> 2) . distance)
    where
        distance (sticker, spot) = sticker - spot
```

Putting it all together in the final few minutes, the full solution was:
```haskell
minimumBribes :: [Int] -> IO ()
minimumBribes q
    | invalidInput indexed = putStrLn "Too chaotic"
    | otherwise = print $ lessThanBehind q
    where
        indexed = zip q [1..]

lessThanBehind :: [Int] -> Int
lessThanBehind [] = 0
lessThanBehind (x:rest) =
    numLessThan 0 rest + lessThanBehind rest
    where
        numLessThan :: Int -> Int -> [Int] -> Int
        numLessThan 2 _ _ =  2
        numLessThan n 100 _ = n
        numLessThan n counter (a:as)
            | a < x = numLessThan (n+1) (counter+1) as
            | otherwise = numLessThan n (counter+1) as
        numLessThan n _ [] = n

invalidInput :: [(Int, Int)] -> Bool
invalidInput =
    any ( (> 2) . distance)
    where
        distance (sticker, spot) = sticker - spot
```
This happened to pass all of the test cases, despite the cost function!

## A scalable solution

Unlike some other problems I've attempted, an efficient and correct solution to this problem only required a small tweak to the original solution.
The "trick" lies in flipping around the `lessThanBehind` check.
Rather than finding how many numbers `n` passed (an equivalent statement to "numbers smaller than `n` appearing after n"), instead look at how many numbers passed `n`.
After flipping things around, its time to establish a search window based on where `n` was found, rather than just hardcoded to some `X` (like 100).

The search window for a given `n` is the range between the value `v` at index `i` and index `i`.
In a line where nobody has passed anyone, each `v == i`.
As people pass each other, `v` will change.
In cases where you find the passer, there's no work to do, since we're looking at how many times a given value was *passed*.
Finally, after walking through the array you'll hit on the passed value `v` at some index `i` larger than where it should be found.
From here, by traversing over the range of indexes from where it should have been found to where it was found, the algorithm counts up all values that are greater than `v`.
This sum is then added to the total count of passes.
And at the end, simply return the total count after traversing the entire input.

This was easier to express in Ruby than Haskell:
```ruby
def minimumBribes(q)
    count = 0
    q.each_index do |i|
        ix = i+1
        v = q[i]
        return puts "Too chaotic" if v > (ix+2)

        # V can move backwards infinitely as others pass it, but only ever forwards twice
        # So check the distance between where v is (ix) and how far it could have been.

        start = [v-1, 0].max
        (start..i).each do |n|
            count += 1 if q[n] > v
        end
    end
    count
end
```

### Reflections

In each of my challenge problems I end up running into trouble finding either a fully correct and/or efficient solution.
In all cases this stems from either mis-reading or not fully understanding the problem statement and constraints.
Its **extremely** important to step back, ignore the timer for a few minutes, and make sure that you have a strong intuition for the shape and constraints of the problem.
