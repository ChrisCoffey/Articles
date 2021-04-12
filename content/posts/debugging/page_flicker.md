---
title: "Debugging Page Rendering"
date: 2020-11-13T16:16:24-05:00
draft: false
categories:
    - debugging
    - browser
---

Debugging rendering issues is a bit of a black art.
Doing so effectively requires understanding the browser's critical rendering path along with how to use a sufficiently powerful debugger.
This article aims to explain the basics of the critical rendering path - although there are far better resources available - as well as how to use Chrome's debugger to identify the issue.

#### A primer on the Critical Rendering Path
After your browser requested this webpage it began a complex dance between three interconnected processes in order to process the HTML & ultimately render a page in the browser window.
When the first bytes of HTML are returned to the browser following a request, it immediately begins parsing the bytes and creating the Document Object Model (DOM).
The DOM is the familiar tree of HTML elements annotated with various attributes.
Once completed, the DOM will contain all of the content for the webpage.
But how are styles applied?

As the browser parses the HTML it typically encounters one or more stylesheets inside `<link rel="stylesheet" .. >` tags.
Parsing these stylesheets adds their contents to the CSS Object Model (CSSOM), which contains all of the page's styles.
This operation is render blocking because the browser cannot paint the page until it understands both the content (DOM) and how to perform layout+styling (CSSOM).
The browser's HTML parsing continues, but the render itself is blocked until the full CSSOM is constructed.

In addition to stylehseets, almost every modern webpage also loads Javascript via `<script>` tags.
Script tags also block rendering because Javascript can modify the content of the page via DOM manipulations.
Even `async` or `defer` scripts impact rendering, but generally don't immediately stop (i.e. block) HTML rendering.
However, CSS parsing blocks Javascript parsing because Javascript can be used to query for the layout impact of CSS on an element.

So, to correctly render a webpage the browser navigates the stop-start CRP dance.
This can have dire consequences on a page's rendering behavior, particularly if inline scripts kick off asynchronous DOM modifications.

If you'd like to learn more, I recommend this short [Udacity course by Google](https://www.udacity.com/course/website-performance-optimization--ud884).

#### Using Chrome's performance debugger
All of the modern browsers have the ability to trace a webpage's performance events like Javascript function calls, painting time, and the time to fetch assets.
But of all the tools on the market, in my experience Chrome is best suited for diagnosing rendering issues.

After accessing the **Performance** tab in Developer Tools you'll see an empty recording window and a few settings on the surrounding frame.

Chrome's debugger has two killer features.
First, the ability to artificially throttle the page's CPU resources widens the window to observing rendering issues.
This saves an enormous amount of time in identifying a successful replication.
The second killer feature is Chrome's `Screenshots` feature.
This annotates the entire performance trace with what the page looked like after the preceding paint.
Meaning, if paint1 completes at T0, then a bunch of JS runs between T1 -> T8, then paint2 runs at T9, the trace will show the page as of paint1 from T1 -> T8 directly above the Javascript before showing paint2 from T10->.
Its impossible to overstate how useful I've found visually scrolling through a webpage's rendered when debugging.

From here, its a matter of visually identifying the error in the debugger and rectifying what you see with your knowledge of how the CRP relates to what you're seeing.
You'll encounter dozens of novel events and almost certainly need to do some research into which ones may cause the issue you're battling.
Google's [Performance Monitoring Events reference](https://developers.google.com/web/tools/chrome-devtools/evaluate-performance/performance-reference) has more details on what various events mean.

#### Conclusion
In short, Chrome's performance analysis tool is excellent for debugging render issues, but there are a couple of prerequisites.
First, you should understand what you're looking for.
Ideally you can find a replication of the problematic behavior, otherwise you'll probably just waste a lot of time looking at tiny screenshots.
Secondly - and less important than a clear replication - is having an intuition for how the browser _should_ behave.
This comes from your knowledge of the CRP & other web development details.
But, armed with at least a replication and a willingness to learn as you go, you should be well on your way to identifying a rendering issue.

Good luck & happy debugging!
