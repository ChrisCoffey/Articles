---
title: "Fixpoints and the Y combinator"
date: 2019-03-28T16:07:37-04:00
draft: false
tags: ["math", "theory", "functional programming"]
---

## What's a Fixpoint?
For some reason, functional programming seems to have developed a reputation for using confusing and/or complex names to describe various concepts.
I recall this being more or less my impression as I transitioned from the "standard" OOP+imperative style into functional programming, so I'd like to start dispelling some of the confusion.
This piece will talk through one of the basic, albeit more obscure, building blocks for functional programming that was a bit intimidating upon my first contact with it.

Fixpoints refer to the value(s) of `x` for which some arbitrary function `f(x) = x`.
I could go through the mathematical definition for this, but to keep things more concrete, here's a Haskell example instead:
```haskell
foo :: Int -> Int
foo x = (x^2) - (3 * x) + 4
```
If you load that function into `ghci` (or try a few values in the polynomial) you'll find that `foo 2 == 2`.
This means `foo` has a fixed point at `2`.

Functions with fixpoints appear in many other flavors beyond simple arithmetic, but they always satisfy the constraint that `f(x) = x`.

### Using Fixpoints in the wild
Before delving into the specifics of how fixpoints are used in functional programming, I'm going to take a brief detour through repetition recursion (foreshadowing the utility of fixpoints!).

As I'm sure you're aware, repetition forms the backbone of most algorithms.
Repetition comes in two flavors, _bounded_, where something occurs a fixed number of times - , and _unbounded_, where something happens until a boolean condition is met.
It should be clear that bounded repetition is simply a less-general version of unbounded repetition, because you can implement it given the condition `steps == n` along with unbounded repetition.
Therefore, let's refresh our memories on how unbounded repetition is implemented in imperative and functional programming languages.

For most people learning to program, the _for_ loop is the first repetition structure encountered, with _while_ shortly after.
As stated above, you can trivially implement a _for_ loop if you have a _while_ loop.
In functional languages, both bounded and unbounded repetition are implemented using _recursion_.
The fact that there is only one looping construct in FP is both a blessing and a curse, since it keeps things simple once you've wrapped your head around recursion, but certainly complicates things for those coming from an imperative background.

Actual implementations of recursion vary depending on the infrastructure provided by the language in question.
If, for example, you happened to be writing in a modern programming language with lexical scoping, you could simply refer to the function body you'd like to recursively call by name.
On the other hand, if you were writing your program in the untyped lambda calculus (or any other language without lexical scoping) you'd find yourself unable to reference functions by name & instead would need some new machinery to accomplish repetition.
You could brute-force bounded repetition by manually repeating the same call _n_ times, but that way seems like it'll quickly lead to madness and still doesn't provide unbounded repetition.
Thankfully, the logicians/computer scientists originally thinking about this problem devised a far more powerful way to introduce repetition, passing along a first-class function.

The idea of passing along a reference to the function itself as an argument out of necessity may seem quaint, but in a system like raw lambda calculus with its rigid variable replacement its essential to use an additional parameter & pass along the function itself as an argument.
So what does that actually mean?
```
addFixed f x y =
    if isTheEnd y
    then x
    else f f x y
```
Basically, by writing a function that takes a copy of itself as an argument we're able to avoid having any by-name references to `addFixed` in the function body.
That in turn means that when we call `addFixed addFixed 1 2`, the `f` in the body is actually a copy of `addFixed`!
It may take a bit of squinting, but this provides recursion, and therefore unbounded repetition in languages that do not support referencing functions by name!

The `addFixed` example is more than a bit contrived, and in fact there's actually a general function that greatly simplifies this which I'll discuss in the next section.

### The Y combinator
Rather than always defining functions with a parameter to pass along a copy, its possible to define a higher-order function that automatically does this for you.

```
recursive f = λa.(f (a a)) λa.(f (a a))
```
This is just such a function. When given a function as an argument, it constructs a new function that both evaluates the function with its arguments, and passes along a copy of the original function `f`.
`recursive` has another far more well-known name, *Y*.
The Y combinator is truly remarkable, but for it to work the function provided must have a valid fixed point.
What construes a "valid" fixed point?

In mathematics, the functions for which Y works have what are referred to "attractive fixed points".
Simply put, attractive fixed points are values of _x_ that the function `f` will settle on for any value `y` that is "sufficiently" close to `x`, where "sufficiently" is defined on a function-by-function basis.
In other words, `x = f(f(f(f(f(f(....(f(y).....)`.
Attractive fixed points often arise when a function has some sort of termination condition built in, such as checking if a numerical argument is zero.

In Haskell, it isn't possible to implement Y directly, but a similar function by the name `fix` can be found in `Data.Function`.
It bears the signature `(a -> a) -> a`, which when taken with the semantics of Y means "given a function on some type `a` that has an attractive fixpoint, `fix` will find said fixpoint".
The implementation for `fix` takes advantage of Haskell's lazy `let` bindings:
```
fix :: (a -> a) -> a
fix f = f (fix f)
```
Attempting to implement the actual Y combinator as previously defined results in an infinite type, since the first argument is a copy of the function itself, which must have a signature that can take a copy of itself, etc...

### Have I ever actually needed to use Y or fix in my daily work?
As a programmer working in industry, no. But they've certainly helped me stretch my brain!
