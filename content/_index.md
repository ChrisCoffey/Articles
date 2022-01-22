---
title: "Welcome to Foldl"
---

#### What's a foldl?

Also known as reduce or accumulate, **folds** are a family of a higher-order function that traverse a data structure and "compresses" it into a new value. `foldl` is the left fold function: `(accumulator -> a -> accumulator) -> accumulator -> t a -> accumulator`. That means you provide an accumulation function, an initial value for the accumulator, and the data structure "full of" `a`s, and `foldl` returns the accumulator.

As for this website, it's where I host my writing about programming and management.
