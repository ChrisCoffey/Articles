---
title: "Introduction to Untyped Lambda Calculus"
date: 2018-11-10T23:32:42-05:00
draft: true
---
A few weeks ago I gave a talk at work about Lambda Calculus. I had intended to speak only about Curry's paradoxical Y-combinator (post about that is forthcoming), but ended up spending two-thirds of my time trying to explain the Lambda Calculus. Afterwards a few teammates suggested that the material in that talk would be better served with a blog post, so here we are.
What practical value will learning Lambda Calculus have for your day-to-day work? Probably none. But its fascinating and well worth a quick journey down the rabbit hole.

#### The Origin Story
The beginning of the 20th century must have been an exciting time to be a mathematician. The first international congress of mathematicians had occurred in 1897, and following it's success a second took place in 1900. The second ICM was attended by Klein, Cantor, Markov, and Hilbert (among many others), and it was at the 2nd ICM that Hilbert posited his famous 23 problems. These problems had a major impact on mathematics in the 20th century, but it would be hard to argue that any has been more influential than his 10th problem.
Hilbert's 10th problem asks whether there is, when given a Diophantine equation (a polynomial with any number of unknown variables and integer coefficients), there exists a process that can determine using a fixed number of operations whether the equation is solvable using integers for each unknown. The trick is that Hilbert was asking whether there was an algorithm for _any_ Diophantine equation. The mathematicians of the time quickly realized that in order to prove or disprove this question two different cases needed to be met. For the affirmative, you simply needed an _algorithm_ that could return `True` or `False` when given a Diophantine equation, without actually understanding or formally defining what an algorithm actually is. Proving the negative, or absence of such an algorithm, on the other hand requires you to first formally define what an algorithm is becuase you must prove that no algorithm can possibly exist that solves this problem. I.e. How can you prove that no algorithm can possibly exist, rather than just that you weren't able to find one that worked?
If this sounds similar to the _Halting Problem_, that's because Hilbert's 10th problem gave birth to Alonzo Church's work on _recursive functions_. Roughly, in mathematics a recursive function is one that has an inductive definition. Of particular interest were the _primitive recursive functions_, or those functions that, given a small set of "base" functions like `const` or `succ`, can be constructed using only substitution as in `(x+y)² ∼ prod(sum(x,y), sum(x,y))` or  primitive recursion (separate from a primitive recursive function) which is quite similar to induction from some base input up to the target `t`. If you think about primitive recursive functions as a pure `fold` over some data structure, it should be come apparent that there should exist an algorithm to compute the result of any primitive recursive function. Church realized that these primitive recursive functions were all computable, but also asked whether there was a larger class


### The Basics
Untyped lambda calculus consists of just two key operations, abstraction to a function and function application. Abstraction introduces a single variable into an expression, while application replaces all occurences of a single variable with a provided expression. Let's see what these two operations look like:
```
-- abstract some variable a
λa. a

-- apply the expression b to expression a.
a b
```

But what does this buy you?

#### The Rules
