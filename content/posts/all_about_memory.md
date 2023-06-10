---
title: "All About Memory"
date: 2021-01-26T13:57:20-05:00
draft: true
tags:
    - Programming
---

Talk through the early days of computing. Von Neumann computers and the Harvard vs. Princeton architecture. Why might a designer choose one over the other?
Point to costs for different types of

Modern machines have grown much faster, but cost ratio between RAM & HD (even SSD) has remained approximately 10:1.

Even within RAM, there is a huge difference between static RAM (SRAM) and dynamic RAM (DRAM).
SRAM is much faster and consumes less power than DRAM, but it has much worse information density and costs far more due to its complexity (about 100x the cost).
Briefly explain difference between SRAM and DRAM.
Also, RAM is volatile.

First some definitons.
HD
RAM
Register

Now, as Von Neumann and his collaborators said back in the early days of computing "developers will want an infinite amount of fast memory".
Unfortunately, the costs shown above simply don't make that economically feasible.

Instead, computer architects have devised memory hierarchies that allow blazing fast memory, while trying to minimize the overall cost of the system.

Innovation of providing a unified memory interface to programmers is that we don't have to care about all the different types of memory.

After all, a CPU can only interact with registers, or request data from main memory.

But HD is where all of the code lives.
How does the CPU get the code to run? This is the question to explore during the talk

---------


