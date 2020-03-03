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

This weeks problem comes from [HackerRank](https://www.hackerrank.com/challenges/count-triplets-1/problem?h_l=interview&playlist_slugs%5B%5D=interview-preparation-kit&playlist_slugs%5B%5D=dictionaries-hashmaps).
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


#### A scalable solution
