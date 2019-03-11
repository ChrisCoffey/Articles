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
    - Talk through the "traditional approach"
        - Tree of function calls, with state stored in the call stack
        - subroutine -> create a new stack frame & allocate locals into it. subroutine returns & the stack frame is popped (and value returned)
    - Continuation passing is what happens when you remove the concept of a function "return" from the language
        - If functions do not return, then you can only ever call a function once. This means you need to think about control flow differently!
        - So, what can you do in any given function?
            1) Assignments
                - variable
                - anonymous functions
            2) Call a function
    - Why is it useful?
        - What does a callstack do?
        - What happens if you recurse too deeply? (some languages optimize away tailcalls, others do not). CPS doesn't care.
        - Implemnt new control flow primitives
            - try/catch as an example
                - quite complicated
        - In fact, because CPS is the essence of determining "what executes next", any control flow you can imagine can be implemented via CPS
            - But its really verbose
    - Where is it commonly used? Any particular languges/ frameworks?
        - async/await frameworks, javascript promises,
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

