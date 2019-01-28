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

Well, implementing the library using an abstraction does make the code a bit more difficult to understand during a first read and rule out a few optimizations.
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
The loosely typed `insertBucket :: Word8 -> Word32 -> Maybe Word32` function does the job, but it relies on the author to always jump between a value's representation & its semantics.
Since I don't like doing that, I ended up with `insertBucket:: Fingerprint -> Bucket -> Maybe Bucket`, which more clearly indicates what this function actually does.

In all honesty, I think the newtypes probably prevented me from writing 5-10 bugs, but the tests probably would have caught them anyways.
More than anything, I find them a useful guide for improving my development velocity.
Although they'll certainly help if/when I need to extend the library too.

### Performance Testing
As mentioned in [part 1](/posts/cuckoo_filter_1), cuckoo filters were designed to solve a very particular performance problem, namely how to answer approximate set membership questions about extremely large sets.
For this library to be an effective tool, it needs to perform acceptably well in terms of both time & space consumed.
If it is too slow, you'd be better off using a database of some kind.
If it uses too much memory, you'd be better off using `Data.Set` directly.
Thankfully, `cuckoo-filter` seems to acceptable in both regards.
That isn't to say that its particularly good with either memory or time, but it seems to be sufficiently good to be useful.
The remainder of this section explains how I went about profiling and improving the library.

As we all know, the first step to any performance work is to establish a baseline.
In the case of `cuckoo-filter`, I was lucky enough to find a bloom filter library by Bryan O'Sullivan.
His library contains a file with the English language in it.
This file is a common benchmark for both bloom and cuckoo filter libraries, so I decided to use it for this library as well.

After writing a quick harness it was time to start profiling.
GHC makes this absurdly easy.
By simply enabling the `-prof -fprof-auto -rtsopts` flags on the test harness and recompiling the library, I was able to run the harness with `+RTS -p` enabled.
This produces an automatically generated and allocated cost-center report, i.e. the data you'd need to create a flame graph.
That was extremely useful for reducing unnecessary cycles in the library and more importantly removing unnecessary allocations.
There was one place early on where I had unnecessarily wrapped some data in `[]` and forgotten to remove it (I was computing the hash, so leaving it wrapped worked fine).
Turned out that the allocations & subsequent collection of these list constructors accounted for ~45% of the program's runtime! The unnecessary list was dropped immediately.

After many iterations with the cost center profiler, I took a quick look into the heap allocations.
This is the other primary form of profiling GHC offers out of the box (please see [the docs](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/profiling.html) for more details).
Where the cost center is all about telling developers where time is being spent, the heap profiles indicate which data is in residency over the program's lifetime.
I.e. if you're leaking data somewhere, this is a great way to find it.
For this particular library, the heap profiles were not very interesting. The vast majority of data in memory were `Word32` values, which is exactly what I'd expect in a hash table.
Unfortunately, it showed that there was too much memory in use relative to the theoretical limits for cuckoo filters, which I attribute to my decision to use 8-bit fingerprints rather than the more efficient 7-bit prints.

Having established a baseline, I also wanted to understand the behavior of the library under different loads.
This behavior is predicted in the paper, but given that I implemented this library it was important to make sure it at least aproximated the behavior from the paper.
I went about verifying this by adding a handful of `Criterion` benchmarks. For those who are not familiar, `Criterion` is a small library for writing microbenchmarks (i.e. performance unit tests). It provides a number of useful helper functions, as well as the machinery to run hundres of loops over your test case before reducing the results down to the relevant statistics. I'm a big fan of this approach.

The micro benchmarks showed that the library was performing good but not great.
With that in mind and the initial goal satisfied, I put the project down for a few months. I'll hopefully dive back in to the performance this spring once things calm down at work.

