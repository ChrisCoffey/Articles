---
title: "Special Strings"
date: 2020-02-17T13:48:19-05:00
draft: false
categories:
    - algorithm
    - interview
---

This is the first in a series of posts where I'll introduce an interview problem I've never solved before and attempt to solve it in an hour.
I'll show what was achieved in that hour, then proceed to implement a full solution to the problem if I failed to initially do so.

## Counting Special Strings

#### The problem

Via [HackerRank](https://www.hackerrank.com/challenges/special-palindrome-again/problem), this problem asks us to solve the following:

A string is said to be a special string if either of two conditions is met:

  -  All of the characters are the same, e.g. aaa.
  -  All characters except the middle one are the same, e.g. aadaa.

A special substring is any substring of a string which meets one of those criteria. Given a string, determine how many special substrings can be formed from it.

For example, given the string `s = mnonopoo`, we have the following special substrings: `{m, n, o, n, o, p, o, o, non, ono, opo, oo}`

#### The test cases

1. `aaaa` -> **10**
2. `asasd` -> **7**
3. `abcbaba` -> **10**

#### One hour attempt

Spoiler, I made a big mistake in the opening minutes of this problem.
I started this problem by trying to identify some smaller sub-problems to attack.
The test data & problem statement suggested that this might be the kind of problem amenable to a divide and conquer strategy (it isn't), so I quickly sketched out a recursive algorithm.

Before actually writing any code I realized that the algorithm I was considering wouldn't cover _all_ the different conditions, but sketching something out helps learn and understand the problem.
So I ran the following against the test cases:

```haskell
substrCount_Wrong :: Int -> String -> IO Int
substrCount_Wrong _ [a] = pure 1 -- The terminal case. Stop recursing
substrCount_Wrong _ [a,b] = do -- A trivial divide case
    let x = if a == b then 1 else 0
    a' <- substrCount_Wrong 0 [a]
    b' <- substrCount_Wrong 0 [b]
    pure $ a' + b' + x

-- This is the meat of the algorithm. Given an input string, it forks based on the length of the input string.
-- In the event of an even string, it evaluates for "specialness" then recurses on to the tail

-- For an odd length string, it splits on the middle, recurses on the left & right halves
substrCount_Wrong _ s
    -- Recurse on the tail
    | even (length s) && allSame = do
        x <- substrCount_Wrong 0 remainder
        pure $ 1 + x

    -- Recurse on left & right halves of the string
    | odd (length s) = do
        let len = length s `div` 2
            start = Data.List.take len s
            end = Data.List.drop (len + 1) s
            matches = start == end && checkAllSame start

        -- Recurse on left & right halves
        left <- substrCount_Wrong 0 start
        right <- substrCount_Wrong 0 end
        pure $ left + right + 1 + (if matches then 1 else 0)

    -- Recurse on tail
    | otherwise = substrCount_Wrong 0 remainder
    where
        allSame = checkAllSame remainder
        checkAllSame = all (\c -> c == Data.List.head s)
        remainder = tail s
```

This algorithm is broken in some fundamental ways.
Namely, it moves from left -> right, evaluating __all__ the remaining characters as it goes; this means the final element is pinned to the final character of the string.
Think about what happens in a string like `aaaa`, which produces the following special strings:
- 4x `a`
- 3x `aa`
- 2x `aaa`
` 1x `aaaa`

There are ten valid substrings produced by `aaaa` using a correct algorithm.
My broken recursive algorithm produces only 7:
- 4x `a`
- 1x `aa`
- 1x `aaa`
- 1x `aaaa`

The problem is the left -> right behavior mentioned above.


Flailing through the recursive approach burned up ~25 minutes of my hour.
So, with 35 minutes remaining I got to thinking about how what a correct algorithm would look like.
In the course of checking the recursive solution I realized a correct algorithm needs to examine all the 1-letter substrings, then all of the 2-letter ones, etc...

The brute-force version of this is:
```haskell
substrCount :: String -> Int
subStrCount str = length . filter isSpecialString $ findAllSubstrings str

findAllSubstrings :: String -> [String]

isSpecialString :: String -> Bool
```

That algorithm inutitively seems correct.
It breaks the overall problem down into 1) generating all the substrings and 2) checking if an individual substring is special.
If each of the subproblems is implemented correctly, this must also produce a correct result.

Around 10 minutes later the following code was running:

```haskell
substrCount :: String -> Int
substrCount [] = 0
substrCount str =
    length $ Data.List.filter isSpecial subs
    where
        subs = subseqs str

        isSpecial [c] = True
        isSpecial s = allMatch s || headTailMatch s

        allMatch s = all (\c -> c == Data.List.head s) s
        headTailMatch s = let
            h = Data.List.take (Data.List.length s `div` 2) s
            t = Data.List.drop ((Data.List.length s `div` 2) + 1) s
            in h == t

subseqs :: String -> [String]
subseqs str =
    concatMap (slidingWindow str) [1..length str]
    where
        slidingWindow ::
            String
            -> Int
            -> [String]
        slidingWindow str n
            | length str == n = [str]
            | otherwise = let
                xs = Data.List.take n str
                in xs : slidingWindow (tail str) n
```
Running this against the three basic test cases passed.
Unfortunatley, when running it against the broader set of test cases it failed on all but the shortest examples.

The good news for the algorithm is that every single failure was due to timeouts in the test engine rather than proucing an incorrect result.
However, a failure is a failure.
And in the case of the brute-force approach implemented above, generating `O(n^2)` substrings before checking them was going to fall flat on its face for any large input.
Knowing this, the testcase designers had included a few strings around 1,000,000 characters long.
That works out to ~10^12 substrings to check, which at a rate of 100k substrings per-second would take 115 days to fully evaluate a single test case.
There are 15 test cases.
Brute force wasn't going to work.

At this point I still had ~15 minutes left on the clock so I poked and prodded at optimizing the algorithm I had working.
But, I didn't come up with anything more than some minor tweaks, when a completely different algorithm was actually required.
So the hour elapsed with a bit of a whimper and I went on to continue thinking about how to optimize and improve the algorithm.

#### A scalable solution

After an hour of twiddling and prodding I poked around the internet and uncovered a more successful solution attempt.
The core idea behind this solution is reducing the problem in a fundamentally different way than I had chosen to.
In many problems its possible to change the initial shape of the problem via pre-processing before actually finding the solution.
In the problem at hand, pre-processing can lead to a dramatic reduction in complexity.
That clever pre-processing step involves converting the string into a list of run-length encoded tuples, i.e.:
```
> str = "aabaaacbbb"
> runEncode str
> [('a',2),('b',1),('a',3),('c',1),('b',3)]
```

Rather than evaluating individual substrings, the algorithm instead focuses only on a sliding window of 3 elements at a time.
Now, its important to keep in mind that "element" in this case refers to a `(Char, Length)` pair, not an individual character.
Let's take a look at how compressing the original string changes the shape of the analysis algorithm by manually evaluating a few cases from the example above.
We'll work from right -> left just like in the naive recursive algorithm, except this time there is no need to divide an conquer.

1. The first pair, `('a', 2)` contains 3 special strings: `a`, `a`, `aa`
2. This is followed by a single `b`, so that must be a single special string
3. Finally, `('a', 3)` results in 6 substrings, all of which are the same string and therefore special: `a`, `a`, `a`,`aa`, `aa`, `aaa`
4. Before moving on to look at the fourth pair, its time to examine the first three to see if they form a palindrome with a single letter in the middle.
There is only a single `b`, so there are also _at least_ one special strings here.
The number of special strings is determined by the smaller of the left or right half of the palindrome.
So in this case, `('a', 2)` means there are two additional special strings: `aba`, `aabaa`

Those are the rules for analyzing a run-lenght encoded compressed string.
The best part is that its obviously been reduced from an O(n^2) algorithm down to O(n) thanks to some intelligent preprocessing.
Its also possible to do this in a single pass over the compressed list because the number of identical character palindromes is equal to the number of substrings in a run, which can be found via the equation `n*(n+1)/2`.
That saves a some tedious programming and unnecessary looping.

Here's the code for the solution:
```haskell
subStrCountFast ::
    String
    -> Int
subStrCountFast str =
    palindromeCount + runScores
    where
        palindromeCount = countPalindromes runs

        runs = encodeRuns str

        runScores = Data.List.sum $ runSubStrs <$> runs
        runSubStrs (_, x) = (x * (x+1)) `div` 2

countPalindromes ::
    [(Char, Int)]
    -> Int
countPalindromes [(a, an), (b,1), (c,cn)]
    | a == c = min an cn
    | otherwise = 0
countPalindromes [a,b,c] = 0
countPalindromes ((a, an):(b,1):(c,cn):rest)
    | a == c = let
        palindromeCount = min an cn
        in palindromeCount + countPalindromes ((b,1):(c,cn):rest)
    | otherwise = countPalindromes ((b,1):(c,cn):rest)
countPalindromes (a:b:c:rest) = countPalindromes (b:c:rest)
countPalindromes _ = 0

encodeRuns ::
    String
    -> [(Char, Int)]
encodeRuns [] = []
encodeRuns (x:rest) = let
    len = run rest
    in (x, len + 1) : encodeRuns (Data.List.drop len rest)
    where
        run [] = 0
        run (a:as)
            | a == x = 1 + run as
            | otherwise = 0
```

## Takeaways

1. Slow down at the start and examine the problem.
Play with several different types of test cases.
I got into trouble by examining one test case for which a divide and conquer solution seemed promising, when in fact it was completely wrong.
2. Go for a brute-force solution to make sure the problem's shape is understood
3. See if there are ways to reframe the problem from the brute-force solution into something with better asymptotic behavior
