---
title: "Hunting for a match"
date: 2020-03-31T06:58:17-04:00
draft: true
categories:
    - algorithm
    - interview
    - array
---

This post continues the series of interview problem breakdowns.
In this series, I attempt an interview problem from somewhere on the internet that I have never seen before and share all the details with you.
I set a limit of one hour for the initial attempt, then follow up with a correct solution regardless of how long it takes.

## Hunting for a match

With all the changes and a new schedule for my toddler its been difficult to find the time to work on these challenges
In fact, this is the first problem I'm attempting under "lockdown".
Its nice to be getting back to drilling on these problems, even if this one felt much easier than the others.

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

Despite being a simple problem, there were


## A scalable solution


### Reflections


