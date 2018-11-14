---
title: "Cuckoo Filters: Part 1"
date: 2018-10-28T16:07:29-04:00
draft: false
---

- Intro with why it became interesting
    - Link tracking
    - Spell checking
    - Bloom filters
- Description of how cuckoo filters work, but refer to paper for details and proofs
    - Specifically a compare/contrast with bloom filters
- Talk through how the library came together.
    - Reference bos' Bloom-filter library
    - Initial implementation & design choices
        - pure vs. mutable
            - How this informs the data structures chosen
        - how heavily to use types
        - Things I wish could be suported, but simply can't
    - Profiling and measuring
        - using criterion for simple insert benchmarks
        - tracking memory using GHC's profilng flags via `stack build --profle`


