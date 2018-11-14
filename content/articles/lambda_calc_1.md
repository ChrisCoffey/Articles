---
title: "Introduction to Untyped Lambda Calculus"
date: 2018-11-10T23:32:42-05:00
draft: false
---
A few weeks ago I gave a talk at work about Lambda Calculus. I had intended to speak only about Curry's paradoxical Y-combinator (post about that is forthcoming), but ended up spending two-thirds of my time trying to explain the Lambda Calculus. Afterwards a few teammates suggested that the material in that talk would be better served with a blog post, so here we are.
What practical value will learning Lambda Calculus have for your day-to-day work? Probably none unless you work on proving properties of other languages that reduce to λ calculus. But its fascinating and well worth a journey down the rabbit hole.

### The Origin Story
The beginning of the 20th century must have been an exciting time to be a mathematician. The first international congress of mathematicians had occurred in 1897, and following it's success a second took place in 1900. The second ICM was attended by Klein, Cantor, Markov, and Hilbert (among many others), and it was at the 2nd ICM that Hilbert posited his famous 23 problems. These problems had a major impact on mathematics in the 20th century, but it would be hard to argue that any has been more influential than his 10th problem.
Hilbert's 10th problem asks whether there is, when given a Diophantine equation (a polynomial with any number of unknown variables and integer coefficients), there exists a process that can determine using a fixed number of operations whether the equation is solvable using integers for each unknown. The trick is that Hilbert was asking whether there was an algorithm for _any_ Diophantine equation. The mathematicians of the time quickly realized that in order to prove or disprove this question two different cases needed to be met. For the affirmative, you simply needed an _algorithm_ that could return `True` or `False` when given a Diophantine equation, without actually understanding or formally defining what an algorithm actually is. Proving the negative, or absence of such an algorithm, on the other hand requires you to first formally define what an algorithm is becuase you must prove that no algorithm can possibly exist that solves this problem. I.e. How can you prove that no algorithm can possibly exist, rather than just that you weren't able to find one that worked?
If this sounds similar to the _Halting Problem_, that's because Hilbert's 10th problem gave birth to Kleene's work on _recursive functions_. Roughly, in mathematics a recursive function is one that has an inductive definition. Of particular interest were the _primitive recursive functions_, or those functions that, given a small set of "base" functions like `const` or `succ`, can be constructed using only substitution as in `(x+y)² ∼ prod(sum(x,y), sum(x,y))` or  primitive recursion (separate from a primitive recursive function) which is quite similar to induction from some base input up to the target `t`. If you think about primitive recursive functions as a pure `fold` over some data structure, it should be come apparent that there should exist an algorithm to compute the result of any primitive recursive function. Kleene realized that these primitive recursive functions were all computable, but also asked whether there was a larger class of functions that were also computable without necessarily being primitive recursive. But what do recursive functions have to do with lambda calculus?
At the same time that Kleene was developing his theory, Alonzo Church was working on a similar model of computation that used structured function application. Shortly after Church published his breakthrough paper on computability, his doctoral student Alan Turing published his doctoral thesis that brought the world Turing machines and their symoblic manipulation approach to computation. All three models have been proven equivalent, and given that you're likely already familiar with Turing machines, let's learn about the λ calculus!

### The Basics

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


#### Evaluating Lambda Calculus Terms

A lot of the beauty of lambda calculus rests in the simplicity of its rules. There are several different evaluation strategies for λ expressions, of which I'll discuss _applicative order_ and _normal order_. However, before getting to the evaluation strategies its important to cover the reduction rules that are combined to actually perform an evaluation. There are three different reduction rules: β-reduction, α-conversion, and η-reduction.

##### β-reduction (beta)
β-reduction represents replacing a bound variable with its associated argument in an expression. For example, `λfunc.λarg.(func arg) f a` would go to `(f a)`. As you can see, this is a simple substitution operation.

##### η-reduction (eta)
η-reduction is a tool for simplifying exprssions by removing unnecessary arguments. For those of you familiar with the Haskell tool `hlint`, you've seen your share of `eta-reduction` hints when expressions take the form `doFoo a b = bar a b`. This is of course equivalent to `bar`. In lambda calculs, the expression `λname.(func name)` is equivalent to `func`, because `λname.(func name) arg` goes to (for which I'll use → from now on) `(func arg)`. I.e. `name` isn't providing any value in this computation, so we can cut it out and focus on the important parts, `func` and `arg`.

##### α-conversion
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

#### Evaluation Strategies
The two evaluation strategies I'm familiar with are _applicative order_ and _normal order_. To fully appreciate the difference between the two strategies, lets talk about _normal form_ first. A λ is in normal form when it can't be reduced any further using α, β, or η. Its important to include term-elimination along with function application because of the following case:
```
foo := λa.a λi.(i i)
bar := λz.λy.(z y) λi.(i i)
-- reuctions

foo → λi.(i i)
bar → λy.(λi.(i i) y)
-- As you can see, bar is no longer a function application, so β can't be applied, but if you apply the same argument to each function, you'll end up with the same result. Hence, applying η during evaluation to normal form is essential.
```
Lambda expressions with the same normal form can be considered equivalent.

Now that we know that λ expressions can be reduced to some terminal state, let's talk about how to do this. In most programming languages, function calls are either call-by-name or call-by-value by default. Normal order is λ calculus' call-by-name evaluation strategy.


### Some Computations
When working with lambda calculus it is important to remember that while you can compute using it, it is not a programming language with built-in support for numbers, arrays, etc... While you can compare the normal form of two expressions to see if they're equivalent, if you'd like to compare an expression to a natural number, you'll need to first implement the natural numbers and a way to compare expressions to them. Its turtles all the way down.


