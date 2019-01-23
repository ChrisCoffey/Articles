---
title: "Cuckoo Filter: Part 2"
date: 2019-01-20T15:14:40-05:00
draft: true
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



        - how heavily to use types
        - Testing
        - Things I wish could be suported, but simply can't



