---
title: "Cuckoo Filter: Part 2"
date: 2019-01-27T15:14:40-05:00
draft: false
toc: false
images:
tags:
  - haskell
---

### The API

Due to the way buckets are maintained in cuckoo filters its possible to perform the three basic set operations, `insert`, `delete`, and `member`.
Those three operations comprise the api into `Data.CuckooFilter` in the [cuckoo-filter library](https://hackage.haskell.org/package/cuckoo-filter) package.
As you'd expect for a data strucure that answers set membership questions, the API behaves exactly like the api for a set, with one big exception.
As discussed in [part 1](/posts/cuckoo_filter_1), cuckoo filters (and cuckoo hashing in general) store fingerprints in hash buckets.
Depending on the bucket size **b** you've chosen, you'll only be able to store/delte the same element **2b** times.

The library provides two different implementations, one pure and one mutable.
For real-world problems I'd strongly recommend the mutable one, as its significantly faster & produces far less garbage.
The pure and impore implementations are `Filter` and `MFilter` respectively.
Each of them implement the `CuckooFilter` typeclass, which is used to implement the three api functions.

There are few small utility functions used for safely creating well-formed cuckcoo filters as well, but they're not particulary interesting, so intersted readers should give the docs a quick read.

#### Constants

The original paper provides empirical results displaying a cuckoo filter's behavior under various workloads based on `(bucket size, fingerprint bits)` pairs.
Based on that data & expected workloads, I've hardcoded the bucket size to 4 & used 8-bit fingerprints.
This has the downside of making fingerprints inefficiently large for small filters, but if you only need to store a few thousand or hundreds of thousands of elements you should use `Data.Set` instead.

### Experience Report From Writing The Library

ONe of the key design decisions in `cuckoo-filter` was to provide the interface for the filter as a typeclass rather than implementation-specific functions.
The actual api functions `insert`, `delete`, and `member` are all implemented in terms of this common interface.
Was this a good idea?

Well, implemeting the library using an abstraction does make the code a bit more difficult to understand during a first read and rule out a few optimizations.
But despite those issues, implementing in terms of the `CuckooFilter` typeclass made writing the tests for the library really easy.
The main complexity lives in the three API functions, not in the data structures themselves, so factoring out things like how to write to a bucket or how to create the data structure were extremely helpful.
Doing so kept me from worrying about the details.

To be completely transparent, I only settled on the typeclass based design after implementing the full library using the pure representation.
When it came time to implement the mutable version, I ended up rewriting everything in terms of the typeclass first.
Only then after the tests passing again did I add the mutable implementation.
There were a handful of design bugs that I needed to fix due to the different ways you interact with an `IOArray` versus an `IntMap`, but otherwise this was painless.

Another major design decision was to give everything types.
While newtyping everything is idiomatic Haskell these days, I'm still shocked at the number of libraries on Hackage that don't use newtypes.
In `cuckoo-filter` the buckets, fingerprints, and each hash function were given their own types.
The `insertBucket` function attempts to insert an 8-bit fingerprint into a bucket, which contains up to 4 fingerprints.
The loosely typed `insertBucket :: Word8 -> Word32 -> Maybe Word32` function does the job, but it relies on the the author to always jump between a value's representation & its semantics.
Since I don't like doing that, I ended up with `insertBucket:: Fingerprint -> Bucket -> Maybe Bucket`, which more clearly indicates what this function actually does.

In all honesty, I think the newtypes probably prevented me from writing 5-10 bugs, but the tests probably would have caught them anyways.
More than anything, I find them a useful guide for improving my development velocity.
Although they'll certainly help if/when I need to extend the library too.

