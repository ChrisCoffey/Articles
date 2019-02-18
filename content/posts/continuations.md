---
title: "Co-Routines via Continuations"
date: 2019-02-17T21:06:56-05:00
draft: true
toc: false
images:
tags:
  - Haskell
  - Programming
---
What is CPS?
    - Walk throug how haskell programming is normally done
    - Why is it useful?
    - Where is it commonly used? Any particular languges/ frameworks?
    -
What are coroutines?
Coroutines in C
Coroutines in Haskell

## Control Flow

Typically when we write code, we're writng something like this:
```haskell
concat :: [a] -> [a] -> [a]
concat r = l <> r

alternate :: [a] -> [a] -> [a]
alternate [] _ = []
alternate _ [] = []
alternate (a:as) (b:bs) = a:b : alternate as bs
```

