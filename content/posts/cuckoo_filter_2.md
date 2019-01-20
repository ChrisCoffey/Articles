---
title: "Cuckoo Filter: Part 2"
date: 2019-01-20T15:14:40-05:00
draft: true
toc: false
images:
tags:
  - untagged
---

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
