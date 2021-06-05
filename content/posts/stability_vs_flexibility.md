---
title: "Architectural Tension Between Stability and Flexibility"
date: 2021-05-30T20:59:59-05:00
draft: true
toc: false
images:
tags:
  - architecture
  - management
---

_"Any organization that designs a system (defined more broadly here than just information systems) will inevitably produce a design whose structure is a copy of the organization's communication structure."_
- Melvin Conway

Conway's Law tells us that the systems we create tend to mimic the environments in which they're created.
For those of you who have worked in business with varying styles or both work in industry and contribute to open source, this should intuitively make sense.
In fact, a [2008 paper from HBS](https://www.hbs.edu/faculty/Publication%20Files/08-039_1861e507-1dc1-4602-85b8-90d71559d85b.pdf) had the following to say after researching similar projects (databases, financial modeling, etc...) produced by teams with varying organizational structure:

_We  find  strong  evidence  to  support  the  mirroring  hypothesis.
In  all  of  the  pairs  we examine, the product developed by the loosely-coupled organization is significantly more modular than the product from the tightly-coupled organization.
We measure modularity by  capturing  the  level  of  coupling  between  a  product’s  components.
The  magnitude  of the  differences  is  substantial – up  to a  factor  of eight, in  terms  of  the  potential  for a design  change in  one  component to  propagate  to  others.
Our  results  have  significant managerial implications, in highlighting the impact of organizational design decisions on the technical structure of the artifacts that these organizations subsequently develop._

Rather than dissecting Conway's Law for the _nth_ time, this article explores some of the managerial trade offs mentioned in the HBS paper and how to think about the evolution of a system under active development.

### Tight coupling looks different from textbook cases in practice

Tell story of the CV 1.0 distributed monoloith.
Evolution from true microservices to shared "domain library" that ended up coupling entire system together.
As a result, lack of flexibility on versions or API versioning.
Code generation in the UI as well led to even tighter coupling.

Still deployed independently and scaled nodes independently, but engineering velocity was pretty poor in many cases.
Long builds, long deployments, and difficult to wrangle large changes that rippled across applications.
Also had a single build and single deployment by default, although this could be circumvented.

Felt different from the "big monolith" often used as the epitome of tight coupling, but exhibited all of the same issues on a day-to-day basis.

It optimized for a stable platform.

### Consequences of the tightly-coupled application

Tight coupling is often painted as an absolute negative in software architecture literature.
In my experience, that isn't _exactly_ true.

Over time, tight coupling severely constrains the ability of a system to evolve.
On that point, I'm in agreement with all of the papers and books where I've seen this mentioned.

Specific tight coupling is sometimes a feature rather than a bug.
Particularly in highly-regulated domains, where deviating from a legally mandated retirement can shutter a business overnight.

Incidental vs. necessary complexity. Similarly, incidental vs. necessary coupling.

### How stability was misaligned with business needs and company stage

In the system I described above, we'd optimized for stability and standardization before we really began feeling scaling problems.
In many cases, the software we were building was speculative, but because of idiosyncrasies in the business' operations, we behaved as if they were well-understood problems.
As you can imagine, this led to shipping a lot of software that solved 80% of the requirements, but didn't have sufficient overlap with the "essential 20%" to guarantee success.
This is a quintessential misalignment between a system and the business' needs.

In hindsight, we never should have believed that the requirements were properly understood for any newly-launched application.
At that point, there is almost always a mismatch between what customers say they need and what they actually need, and their first experience using an application are essential to discovering the discrepancy.
Situations with low certainty typically demand high flexibility, so building software to evolve - or even be thrown away - is ideal.

A failure to recognize such misalignment leads to waste.
When biased towards stability when flexibility is required, engineering teams build products that don't meet the customers' needs, then spend many cycles fighting the application's architecture to adapt to what's actually necessary.
Conversely, focusing on flexibility at the wrong time ends with engineering delivering a partially-complete application from the customers' perspective.

Ultimately, one of the most important things an engineering team can do at the start of a project is determine what the business _really_ needs with respect to flexibility or stability.
The best way to determine where on the spectrum a particular project falls is talking about it with folks until they're sick of it.
Poking and prodding until you and your team fully understands _why_ these are the specific requirements and what underlying problem(s) the software addresses is extremely powerful.

### Questions to ask about your system's architecture

1. Why does the system use the architecture it does? Why this architecture?
2. What kind of changes cascade through the codebase? What is the worst-case build time (for a compiled language)?
3. How closely do different teams - or engineers if its a very small team - **need** to communicate?
4. What is the smallest unit you can easily deploy? What about the largest?
5. What are the largest risks facing your business today? Are they rooted in learning (PMF), scaling, or something else?
6. What are the chief complaints and concerns from new engineers - or an imagined new engineer if you haven't added anyone to the team recently.?

Answering those questions tells you a great deal about your system.
For example, if your system architecture evolved organically as your company was searching for PMF and you're currently experiencing scaling issues, that tells you which region of the design space your system currently lives in.
Understanding where your system actually exists in relation to the business - as opposed to an idealized version of it - goes most of the way towards getting the architecture aligned with business needs.
Because after all, the hardest problems in engineering tend to be figuring out which _exact_ problem to solve.

### Contributions

In this post you've learned how even within a single system the tension between stability and flexibility has positive and negative consequence.
Most importantly, I've illustrated how the requirements for a system change over time, requiring modifications to your expectations and cultural norms.
You should feel equipped to look critically at your own system architecture and understand what it optimizes for, and whether that matches what the business needs.



Photo by <a href="https://unsplash.com/@tanguysauvin?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Tanguy Sauvin</a> on <a href="https://unsplash.com/s/photos/tension?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>
