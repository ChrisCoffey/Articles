---
title: "Introduction to Untyped Lambda Calculus"
date: 2018-11-10T23:32:42-05:00
draft: false
---
A few weeks ago I gave a talk at work about Lambda Calculus. I had intended to speak only about the Y-combinator (post about that is forthcoming), but ended up spending two-thirds of my time rushing through an explanation of the untyped Lambda Calculus. Afterwards a few teammates suggested that the material in that talk would be better served with a blog post, so here we are.

The untyped lambda calculus isn't particularly useful for day-to-day programming unless you happen to work in language design, but its fascinating and well worth a trip down the rabbit hole.

## The Origin Story
David Hilbert's work and problems has inspired a significant portion of the mathematical research in the 20th century, but I'm of the opinoin that none of his questions has been more impactful than the Entscheidungsproblem. Translated from German, the Entscheidungsproblem means "decision problem", and asks for an algorithm that returns true or false for an arbitrary statement in first order logic. Orginally discussed by Leibniz in the 17th century, and further explored by Babbage, it didn't see significant attention until re-posited by Hilbert in 1928.

The fascinating aspect of the decision problem is the asymetry between what's required for a positive vs. negative answer. As asked by Hilbet, a positive answer requires an algorithm that provides a true or false answer when given any statement in first order logic, but it says nothing about actually understanding how the algorithm works. So long as the algorithm always returns true or false eventually, the answer is positive. On the other hand, to prove that no such algorithm exists mathematicians researching the Entscheidungsproblem first needed to define what's meant by an _algorithm_. After all, to prove that an algorithm cannot exist you'd need to do more than show that you haven't yet found a solution yet, but actually show taht the very nature of algorithm prevents a positive answer.

If this sounds similar to the _Halting Problem_, that's because the decision problem gave birth to the formal study of _recursive functions_ by Kleene, a doctoral student of Alonzo Church at Princeton in the early 1930's. Mathematically, a recursive function is one that has an inductive definition. Of particular interest to Kleene were the _primitive recursive functions_, or those functions that, given a small set of "base" functions like `const` or `succ`, can be constructed using only substitution as in `(x+y)² ∼ prod(sum(x,y), sum(x,y))` or  primitive recursion (separate from a primitive recursive function) which is quite similar to induction from some base input up to the target `t`. If you think about primitive recursive functions as a pure `fold` over some data structure, it should be come apparent that there should exist an algorithm to compute the result of any primitive recursive function. Kleene realized that these primitive recursive functions were all computable, but also asked whether there was a larger class of functions that were also computable without necessarily being primitive recursive. But what do recursive functions have to do with lambda calculus?

Well, at the same time that Kleene was studying computation using the aforementioned recursive functions, his advisor Alonzo Church was working on a similar model of computation that used structured function application. Shortly after Church published his breakthrough paper on computability, another of Church's doctoral student Alan Turing published his doctoral thesis that brought the world Turing machines and their symoblic manipulation approach to computation. All three models have been proven equivalent, and given that you're likely already familiar with Turing machines and just got a primer on recursive functions, let's learn about the λ calculus!

## The Basics

Untyped lambda calculus consists of two key operations, abstraction to a function and function application. As programmers, we're all comfortable with the idea of abstraction, which I'm taking to mean using variables to stand for concrete values so we can reuse some computation. Similarly, application is the process of mechanically replacing variables in some abstraction with concrete values. In lambda calculus, these abstraction & application operations take the following shape:
```

lambda_expression ::=
    <name>
    -- Abstract a lambda expression into a function
    | λ<name>.<lambda_expression>
    -- Apply a lambda expression to a function, in the form (function argument)
    | (<lambda_expression> <lambda_expression>)
```
As you'll notice, lambda expressions take only a single argument. Expressions like `λa.λb.(a b)` translate to something along the lines of "forall functions a and arguments b, apply a to b". Additionally, the variables `a` and `b` are called _bound_ variables because they are defined and used within the same lambda expression. Variables that occur in an expression but are not defined within it are referred to as _free_ variables. As you can imagine, its impossible to fully evaluate a lambda expression containing free variables. In fact, expressions containing only bound variables are referred to as _closed_. Close expressions are also often referred to as _combinators_ (due to an equivalence to combinatory logic terms).


### Evaluating Lambda Calculus Terms

A lot of the beauty of lambda calculus rests in the simplicity of its rules. There are several different evaluation strategies for λ expressions, of which I'll discuss _applicative order_ and _normal order_. However, before getting to the evaluation strategies its important to cover the reduction rules that are combined to actually perform an evaluation. There are three different reduction rules: β-reduction, α-conversion, and η-reduction.

#### β-reduction (beta)
β-reduction represents replacing a bound variable with its associated argument in an expression. For example, `λfunc.λarg.(func arg) f a` would go to `(f a)`. As you can see, this is a simple substitution operation.

#### η-reduction (eta)
η-reduction is a tool for simplifying exprssions by removing unnecessary arguments. For those of you familiar with the Haskell tool `hlint`, you've seen your share of `eta-reduction` hints when expressions take the form `doFoo a b = bar a b`. This is of course equivalent to `bar`. In lambda calculs, the expression `λname.(func name)` is equivalent to `func`, because `λname.(func name) arg` goes to (for which I'll use → from now on) `(func arg)`. I.e. `name` isn't providing any value in this computation, so we can cut it out and focus on the important parts, `func` and `arg`.

#### α-conversion
As mentioned above, only lambda expressions without any free variables may be fully evaluated. This prevents names from becoming objects in their own right, as you see with atoms in LISP. To point out why this is important, let's consider the following example that attempts to apply `foo` to some function argument (I'll use `:=` to assign names to expressions for reuse):
```
apply := λfunc.λarg.(func arg)
((apply arg) foo)
-- β-reduction
((λfunc.λarg.(func arg) arg) foo) → (λarg.(arg arg) foo) → (foo foo)
```
I was hoping to apply `foo` to `arg`, but ended up applying `foo` to itself due to the name conflict! To avoid introducing this kind of naming conflict under β-reduction, an α-conversion renames variables before replacing any bound variables that cause conflicts. To repeat the same example above, but applying an α-conversion as well:
```
apply := λfunc.λarg.(func arg)
((apply arg) foo)
-- β-reduction
-- α-conversion
((λfunc.λbar.(func bar) arg) foo) → (λ.bar.(arg bar) foo) → (arg foo)
```
Now we're correctly applying `foo` to our `arg` function. Great success.

*Note:* An equivalent way of avoiding collisions is to remove variable names entirely using De Bruijn indices. This is an ordinal system that equates variables to the number of λ's between the variable's usage & where it is bound. For example: `λa.λb.(a) → λλ2`. Personally, I find giving things names much more clear, but using an ordinal system does simplify tracking variables if you happen to find yourself writing a λ calculus interpreter.

### Evaluation Strategies
The two evaluation strategies I'm familiar with are _applicative order_ and _normal order_. To fully appreciate the difference between the two strategies, lets talk about _normal form_ first. A λ is in normal form when it can't be reduced any further using α, β, or η. Its important to include term-elimination along with function application because of the following case:
```
foo := λa.a λi.(i i)
bar := λz.λy.(z y) λi.(i i)
-- reuctions

foo → λi.(i i)
bar → λy.(λi.(i i) y)
```
As you can see, bar is no longer a function application, so β can't be applied, but if you apply the same argument to each function, you'll end up with the same result. Hence, applying η during evaluation to normal form is essential. Lambda expressions with the same normal form can be considered equivalent. Now that we know that λ expressions can be reduced to some terminal state, let's talk about how to do this.

In most programming languages, function calls are either call-by-name or call-by-value by default. Normal order is λ calculus' call-by-name evaluation strategy. This is accomplished by beginning evaluation with the leftmost reducilble expression (a reducible expression is referred to as a _redex_). Using a normal order β-reduction causes function application to first reduce the entire function body before substituting in the unevaluated arguments. Because we're replacing bound variables in the function body with unevaluated arguments, i.e. the full argument expression, and continue to do so until all arguments have been substituted, normal order evaluation delays argument evaluation until the last possible moment.

Applicative order evaluation on the other hand works by evaluating the leftmost redex that does not itself contain a redex. Because a function body with a redex argument by definition is becomes a redex containing a redex under normal substitution, all arguments must be fully reduced before substitution into the function body occurs. This is why applicative order evaluation is equivalent to call-by-value evaluation strategies.


## Some Computations
Now that we've gotten the basics out of the way, lets see if we can write a few data structures and algorithms. Before going any further though, its important to remember that λ calculus has only application and abstraction for primatives, so if we want natural numbers or booleans, we need to define them from those two primatives.

##### Simple functions
To implement interesting functions and datatypes we need some basic building blocks.
```
id := λa.a

self := λa.(a a)

apply := λfunc.λarg(func arg)

fst := λf.λs.f

snd := λf.λs.s

pair := λf.λs.λaccess((access f) s)
```

Given the above definitions, let's walk through what happens when we evalute `((pair id) apply) fst`:
```
((λf.λs.λaccess((access f) s) id) apply) fst →
(λs.λaccess((access id) s) apply) fst →
(λaccess((access id) apply)) fst →
(fst id) apply →
(λf.λs.f id) apply →
λs.id apply →
id
```

That certainly looks like we're constructing a pair of two values, then applying the selector `fst` to return the first value from the pair. From here, you can easily use `pair` to construct a linked list, or introduce a third argument to create triples & use those to construct a binary tree. Lots of fun to be had with the basic functions.

##### Booleans
Alright, so we can create pairs, get values out of them, and in theory create more interesting data structures from those pieces. But what about boolean logic, something that I always take for granted in programming languages?
```
true := fst

false := snd

if := λl.λr.λpred.((pred l) r) → pair

not := λa.(((if flase) true) a)

and := λl.λr.(((if r) false) l)

or := λl.λr.(((if true) r) l)
```
Given these definitions, lets confirm a few simple expressions:
```
not true →
    λa.(((if flase) true) a) true →
    ((if flase) true) true →
    (true false) true →
    (λf.λs.f  f.λs.s) λf.λs.f →
    (λs1.(f.λs.s) λf.λs.f) →
    λs1.(f.λs.s) λf.λs.f) →
    f.λs.s → false

(or true) false →
    ((if true) false) true →
    ((if true) false) true →
    λpred.((pred true) false) true →
    (true true) false →
    (λf.λs.f λf.λs.f)  λf.λs.s →
    λs1.(λf.λs.f)  λf.λs.s →
    λf.λs.f → true
```

Looks like `not true` evaluates to `false` and `true or false` evaluated to `true`! Personally, I find that you can express things like this using function application pretty mind-blowing.

##### Natural Numbers
During his development of lambda calculus, Alonzo Church devised a way of inductively encoding the natural numbers. Church encoding defines the natural numbers as either `0` or `n+1`. 2 is represented as `(0+1) +1`. The following lambda expressions translate this induction into the calculus.
```
zero := id

succ := λn.λs.((s false) n) → pair false

isZero := λn.(n fst)

pred := λn.(((isZero n) zero) (n snd))
```

Mapping 0 to the identity function, and `+1` to the partially applied `pair` function means we can use the pair accessor functions to implement `isZero` and `-1`. This works because, if you recall from above, `fst` is identical to `true` and `zero` is the identity fuction, so `isZero zero` results in `fst` or true. Similarly, any usage of `isZero n` for some _n_ that is not 0 will result in pulling the first value out of `succ`, which happens to be `false`. Let's see what `isZero ((0+1)-1)` evaluates to:

```
(isZero (pred (succ zero))) →
(λn.n fst) (pred (succ zero)) →
(pred (succ zero)) fst →
(((isZero (succ zero)) zero) ((succ zero) snd)) fst →
((((succ zero) fst) zero) ((succ zero) snd)) fst →
((((λs.((s false) zero) fst) zero) ((succ zero) snd)) fst →
(((((false fst) zero) ((succ zero) snd)) fst →
(((((λs.s zero) ((succ zero) snd)) fst →
((((zero ((succ zero) snd)) fst →
((succ zero) snd) fst →
(λs.((s false) zero) snd) fst →
((snd false) zero) fst →
((λs.s zero) fst →
λa.a fst →
fst → true
```

## In Conclusion
This should have given you a small taste for how lambda calculus works, as well as some context into how it came to be. In a future post I'll explore Curry's paradox & the Y-Combinator, which still just scratches the surface of what's possible in the untyped lambda calculus.
