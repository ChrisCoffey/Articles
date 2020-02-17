---
title: "Tricky Functor instances"
date: 2019-01-13T16:36:32-05:00
draft: false
tags: ["haskell", "types", "theory"]
---

I was recently started reading [Thinking with Types](http://thinkingwithtypes.com/) and came upon a great explanation of variance and the role it plays in reasoning about functions.
You're probably familiar with `Functor`, which says that for some `t a`, if given a function `f :: a -> b`, you can transform the `t a -> t b`. Essentially, the essence of "functor-ness" is the ability to transform a result into another type.
What about "anti-functorn-ness", where you want to transform the input rather than the result of a function from `a -> b`? Is that something interesting and worth exploring?

Indeed it is! The "functor-ness" described above is actually called `Covariance`, and simply means that you can transform the output of some computation `T a`.
Similarly, the "anti-functor-ness" of `T a` is called `Contravariance`, and means that you can transform a `T b` into a `T a` by mapping the input of the computation. There is a third form of variance called `Invariance`, but its not as much fun as co & contra variance.

Type variables in an expression are either positive or negative. In the function `a -> b`, the `b` is positive, while the `a` is negative. Just like integer mathematics, two negatives make a positive, so `(a -> b) -> b` actually has `a` in positive position, meaning this covariant in `a`.
In fact, whether a `T a` is co or contra variant in `a` is determined only by whether `a` is positive or negative. Positive `a` means `Covariance`, while negative `a` means `Contravariance`. If the `a` appears in both positive and negative positions, then its invariant, and therefore not particularly exciting.

Now that we have a few types of variance, lets use them to reason about whether or not some type signatures are `Functor`s in `a` or not.

```haskell
foo :: a -> b

bar :: b -> a

baz :: (b -> a) -> b

fiz :: (a -> b) -> b
```

In `foo`, `a` is the input rather than output, and since we've already established that `Functor`s transform the output, `foo` may not be a functor. To confirm this intuition, we can use our newfound knowledge about variance & notice that `a` occurs in negative position. Since `Functor` relies on the type being covariant in `a`, and covariance is determined by a positive `a`, we can be certain that `foo` is contravariant and therefore not a `Functor`. By the same reasoning, we can be certain that `bar`, where `a` occurs in positive position, is a `Functor`. `baz` is an interesting case because `a` occurs in positive position in the argument function, but the argument function occurs in negative position. Just like basic arithmetic, a positive multiplied by a negative is a negative, so `baz` is contravariant in `a` and not a `Functor`. Again, using the same logic, by flipping the position of `a` in the argument function to negative position & creating a double negative, `a` occurs in positive position in `fiz`. So `fiz` is a `Functor`.

I'll dive deeper into how `(a -> b) -> b` manifests itself as JavaScript style continuations in my next post.
