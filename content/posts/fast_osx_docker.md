---
title: "Fast Haskell builds in Docker on OSX"
date: 2019-04-29T13:22:40-04:00
draft: true
toc: false
images:
tags:
  - "haskell"
  - "docker"
---

1) outline the problem and goal
    - Company builds take upwards of 15 minutes to spin up the local-dev. Actually quote the real amount of time spent on these builds each day
    - Compare against a local build taking 5m30s
    - Point out the wasted time for the organization (hours each day)
    - Why docker compose?
        - Networking
        - Dependency management
        - Ease of setup
2) Investigation
    - Lay out the overall monorepo project layout
        - 58 Haskell packages during a clean build.
        - Reasonably, but not fully parallel
    - What is different?
        - Linux vs. OSX
            - But CI is faster...
        - Docker OSX filesystem implementation
            - Known issues:
                - https://github.com/docker/for-mac/issues/3677
                -
    - Measurements
        - Share measurements of the actual stage times
            - Point out that file copies and such are slow (are they?)
        - Monitor the amount of IO performed
            - Should be the same amount, but taking much longer on Docker
        - Context switches
3) Solutions explored
    - Vagrant
        - Copy files from local into vagrant image, then build in docker or w/in the VM and just copy binaries into Docker
        - Idea is to run a linux VM and avoid bind mounting across OS types
    - Prebuild Haskell builes and ship only the object files into the docker environment
        - Talk about how the linking works (but not too much of a foray into it). Perhaps a link to a more in-depth article?
        - Compiler stages worth mentioning? Or just the flags to make this happen...
        - Alternatively, use the llvm backend instead of asm (which is the default)
