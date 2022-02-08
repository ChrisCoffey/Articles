---
title: "Same problem, different language"
date: 2022-02-06T06:58:17-04:00
draft: true
tags:
    - learning
    - programming
---

Different languages have different strengths and weaknesses, which makes solving certain types of problems easier or more difficult. This post explores the different levels of abstraction commonly used in Ruby vs. Haskell. Typical Haskell code uses a much higher level of abstraction, making the code terse but also difficult for newcomers to understand. On the other hand, Ruby - while not an exceedingly verbose language - is usually written with a lower level of abstraction, making it more accessible yet harder to maintain due to it's lower abstraction level. I demonstrate the different approaches these langugages encourage by showing how to reverse a linked list in linear time and constant space with each of them. I'm not advocating for one tool over the other, but I hope you come away with a more critical eye towards the strengths and weaknesses of your chosen tools.

Before showing Haskell and Ruby < explain algorithm here>

Haskell is a typed functional language that supports immutability and lazy evaluation by default. It started out as a research language and despite it's increasing popularity - although it's still niche - in industry, Haskell is still a research language at heart. The library ecosystem has decades of development behind it, and many of the libraries place mathematical abstractions at the programmer's fingertips. As a result, reversing a linked list has a simple and elegant solution that's inscrutable to anyone that is unfamiliar with the abstractions in use.

```haskell
reverseLinkedList :: [a] -> [a]
reverseLinkedList = foldl' (flip (:)) []
```

The heart of this implementation is the left fold, `foldl'`. Folds accumulate a result while traversing recursive data structures. Left folds work from the left side of the data structure to the right. That happens to be the same required to reverse a linked list. However,

< explain Haskell implementation. Touch on laziness, fold, flip, and pointfree style. Make case this is difficult for newcomers to work with>

< ruby implementation, touching on the reference model, while, and reference swapping. Make case this leads to more bugs in more complex code>

< Conclusion points out the strengths and weaknesses of different tools and argues that we should use them with open eyes>
