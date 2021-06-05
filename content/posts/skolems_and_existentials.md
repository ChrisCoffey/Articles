---
title: "Skolem and existential types"
date: 2021-05-31T23:05:08-05:00
draft: false
tags: ["haskell", "theory"]
---

In this post I explain what skolem variables are and how they relate to existential quantification.
After reading this, you should have an intuition for how skolems work and why existential types are a natural extension from skolems.

### Lots of talk about existential types lately

A couple of months ago a coworker of mine gave a talk on using existential types to address the expression problem.
The talk was great and engaging, and provided a nice refresher on working with existentials - this isn't something I use daily.
Only a day or two later, a former coworker shared a blog post they'd written that _also_ described how existential types can be used to introduce heterogenous collections in Haskell.
And so my curiosity about existentials was renewed.

Several weeks later I was talking with someone about an issue in a typechecker they were investigating.
Berried deep in the code were references to _skolems_, which we talked about for a couple of minutes.
My recollection was fuzzy, so I made a note to go back and refresh my memory.
This post resulted from that follow-up.

### Skolems are type variables that unify with themselves

The following Haskell program assumes the `ExistentialQuantification` language option is enabled.
Enabling existential quantification allows using explicit `forall` annotations in various places.
With `ExistentialQuantification` enabled, the following Haskell program becomes possible:

```haskell
data X a = X a deriving Eq
data Foo = forall a. Eq a => Foo (X a)
eqFoo (Foo a) = a == a
unFoo (Foo a) = a
```
When trying to build this function, `eqFoo` typechecks but `unFoo` fails with
```
    • Couldn't match expected type ‘p’ with actual type ‘X a1’
        because type variable ‘a1’ would escape its scope
      This (rigid, skolem) type variable is bound by
        a pattern with constructor:
          Foo :: forall a1 a2. Eq a2 => X a2 -> Foo a1,
        in an equation for ‘unFoo’
```
Why does `eqFoo` typecheck while `unFoo` fails?
It hinges on how skolem type variables work.

Like I mentioned in the section heading, a skolem can only unify - meaning match against a type variable - with itself.
In `eqFoo`, `a == a` doesn't need any additional information beyond `a`'s type, so everything checks out.
`unFoo` on the other hand, is a lambda defined function with type `forall a b. unFoo :: Foo a -> b`, where `b` is actually `forall c. X c`.
GHC therefore tries to prove `forall a. Foo -> X c`, but because `c` was introduce by the `forall` _within_ `Foo` - in other words it is a new type variable unknown to the signature of `unFoo` - the typechecker fails.

In logic - which I have not studied extensively - skolemization is the process of lifting existential quantifiers out of an expression and moving them _before_ a universal quantifier.
Keeping that in mind, GHC wants the signature for `unFoo` to be `exists z. Foo -> X z`, but unfortunately that isn't something GHC can do as far as I'm aware.

### Existential types poke holes in a skolem

Thinking of a skolem type as a hidden type variable, I've already shown how that the type cannot leak out from the context where it's defined.
At this point, you're probably wondering why someone would ever define a type like `Foo` if skolemization prevents extracting the `X` from it.
Answering that question means turning your attention to `eqFoo` and noticing how it actually does something "useful" (sure, reflexivity isn't particularly interesting) with the `X`.

Existential types in Haskell are an excellent tool for hiding information.
Skolem types are more of a safeguard to ensure that programmers don't try to cast a type variable to something it can't be proven to be.
Through that lens, the constraints placed on an existentially quantified type - like `a` in `Foo`'s definition effectively poke holes into the skolem constant and allow access to specific bits of functionality.

In most cases there isn't much need to use a `Foo` when a definition like `data Foo a = Foo (X a) deriving Eq` could work.
But sometimes it is useful to operate on multiple types that all conform to a specific interface.
Haskell doesn't make it easy to create heterogeneous collections, but using existential types you can define data structures that use skolems and existentials to hide all but the details you've chosen to expose via constraints.
For example, imagine I have an interface for launching things, `class Launch a`.
I can define a `LaunchStack` that works for everything that is launchable like this:

```haskell
data Launchable = forall a. Show a => Launchable a
data LaunchStack = LaunchStack [Launchable]
newtype Ship = Ship Int deriving Show

launchStack :: LaunchStack
launchStack = LaunchStack [Launchable "abc", Launchable 42, Launchable $ Ship 2]

launch :: LaunchStack -> String
launch (LaunchStack []) = ""
launch (LaunchStack (Launchable a:rest)) = show a ++ launch (LaunchStack rest)
```
While I was lazy and used `Show` instead of defining `Launch`, you can see using Launchable hides the details of what type has been added to the stack while still allowing the `launch` function to access the specified interface.
This is a powerful feature for hiding information and programming to a specific interface.
I can't say I use it frequently, but there have been times this has simplified some code in production systems.

### Contributions

In this post I've pointed out an interesting relationship between skolem types and existential quantification.
This makes it easier to understand how existentials and heterogenous collections work in Haskell.
For more in-depth treatment, I recommend reading [this](https://www.microsoft.com/en-us/research/publication/practical-type-inference-for-arbitrary-rank-types/?from=http%3A%2F%2Fresearch.microsoft.com%2Fen-us%2Fum%2Fpeople%2Fsimonpj%2Fpapers%2Fhigher-rank%2F%3Franmid%3D24542%26raneaid%3Dtnl5hpstwnw%26ransiteid%3Dtnl5hpstwnw-6vpz6lhdu12f.i4k5m.mtg%26epi%3Dtnl5hpstwnw-6vpz6lhdu12f.i4k5m.mtg%26irgwc%3D1%26ocid%3Daid2000142_aff_7593_1243925%26tduid%3D%2528ir__xkyvkhf199kfqhnakk0sohzncm2xusmb96zbp6qh00%2529%25287593%2529%25281243925%2529%2528tnl5hpstwnw-6vpz6lhdu12f.i4k5m.mtg%2529%2528%2529%26irclickid%3D_xkyvkhf199kfqhnakk0sohzncm2xusmb96zbp6qh00) 2007 paper, [this](https://stackoverflow.com/questions/12719435/what-are-skolems) SO question, or the [Haskell wiki](https://wiki.haskell.org/Existential_type).


