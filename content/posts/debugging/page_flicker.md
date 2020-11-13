---
title: "Debugging Page Rendering"
date: 2020-11-13T16:16:24-05:00
draft: true
categories:
    - debugging
    - browser
---

This article explains how to debug issues that occur when rendering a webpage, with a particular focus on using a browser profiler.
It focuses on a particularly illustrative bug I recently encountered at work.
My hope is that after reading this you'll have a solid foundation to debug rendering issues in your own pages.

A colleague of mine recently pointed out that pages on our site had an unpleasant flicker during the initial load.
It was incredibly subtle most of the time, but would occasionally take a quarter second.
We'd seen issues with flicker during load immediately after navigating to a new page before where the page was blank for a noticeable length of time before the render started, but this was different.
In our issue, after the page had rendered almost all of the non-image content it would go completely blank before fully rendering a moment later.

Like anytime I'm debugging an issue, I jotted down a quick list of what I knew to be true based on the observations available.
1. There were no errors in the browser Console
2. The flicker appeared on every page on our site
3. It occurred across FireFox, Chrome, and Safari

I prefer to use FireFox, so at this point I opened up the __Performance__ tab and started a recording.
A pair of refreshes later I paused the recording and began to dig in.
I've never had to debug a rendering issue like this before, but in the past FireFox's profiler has been a reliable tool for debugging Javascript.
Alas, FireFox's performance trace didn't divulge much.
It pointed out that the page's framerate was painfully low and that plenty of [reflow](<Add link>) was occurring, but nothing I was able to find by hunting and pecking through the trace divulged any insights into the flicker.

Sometimes familiar tools are not the best ones for the job, and from various searches it seemed like Chrome would offer a superior render debugging experience.
Sure enough, Chrome's profiling experience was easily 10x better than what FireFox offered.
In addition to CPU throttling to simulate a mobile device - a much better experience than running `cputhrottle` against the browser - it also offers two forms of render snapshots!
The first series of snapshots displays whatever the most recent paint looked like alongside the Javascript callstack.
![Main thread stack and associated paints](resources/_gen/images/main_thread.png)
The large gap between the two screenshots means there was no consequential paint during that window.

Having access to screenshots alongside the JavaScript stack makes it trivial to identify the window when the flicker occurred.
Dragging around the timeline's focus box until it encompasses the beginning and end of the blanked-out period.
This places a valid pre-issue paint on the left followed by one or more "flicker" paints, and finally a corrected paint showing the page's content.

The zoom functionality allows drilling in until the timeline & callstack displays 500μs (1/2 a millisecond).
For a 5-10s trace, appropriately focusing where you zoom is incredibly important.
As with most debugging and absent a hypothesis, its typically best to examine the period immediately before the incident begins.
This doesn't always work, but in my situation it turned out to be sufficient.

Talk through the zooming

Also find ways to tie in the additional information being brought to bear on the problem
    - What triggers a paint
    - Do I see any of those events happening?

