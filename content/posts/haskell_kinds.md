---
title: "Haskell Kinds"
date: 2019-09-01T22:28:38-05:00
draft: true
toc: false
images:
tags:
  - haskell
  - types
---

# What I know right now
    - Haskell has a dual-system for types and kinds.
    - Kinds are the "type of a type"
    - All types have a kind
    - The kind of a Haskell value is `*`
    - The kind of a Haskell type constructor with a single argument is `* -> *`
        - Think of `Maybe`
    - Its possible to lift types into kinds
    - `Symbol`, `Nat`, etc... are type-level values, i.e. kinds other than `*`

# Open questions
    - Can you push kinds into types?
    - What does manipulating kinds allow you to do?
    - How to `TypeFamilies` interact with kinds?
    - What are polymorphic kinds, and how do they work?

- [] Read https://diogocastro.com/blog/2018/10/17/haskells-kind-system-a-primer/#levity-polymorphism three times, with increasing depth
    - did 1st read
- [] Review GHC extensions in 8.6
- [] Write up notes after first reading
- [] Implement something using kinds after 3rd reading


## Notes from reading
- Are type constructors inhabited?
    No, it is impossible to instantiate just a `Maybe`. YOu need a `Maybe Int`, or `Maybe a`
- While GHC can normally infer the kinds of type variables, the `KindSignatures` extension allows you to manually specify it
    `data List (a::*) = Cons a (List a ) | Nil
    `class Functor (f :: * -> * ) where ...`
- `ExplictForAll` allows defining each type variable in an expression explicitly
- the kind equivalent of a higher-order function (a function that takes a function like `fmap`), is a higher-kinded type. These are type constructors that take other type constructors as an argument
    Think of monad transformers, or a general `NonEmpty f a = MkNonEmpty {head a :: tail :: f a}` data structure
- `*` actually only encompases the _boxed_ types. It does not include primitive/ unboxed types
- The `MagicHash` extension allows you to use the `#` at the end of a type, which indicates that it is unboxed.
- What does `ConstraintKinds` do?
- Where can a Constraint appear in Haskell type signatures?
- What is datatype promotion?
- What does `datakinds` do?
- What does `typeLits` do?
- What does `PolyKinds` do?
    - Find 3 use cases for it
- What does "levity polymorphism" mean?
- What does the `TYPE` kind represent? How is it used?
- What is `TypeInType` and how does it work?
