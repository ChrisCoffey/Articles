---
title: "Architectural Tension Between Stability and Flexibility"
date: 2020-02-10T20:59:59-05:00
draft: true
toc: false
images:
tags:
  - architecture
  - management
---



_"Any organization that designs a system (defined more broadly here than just information systems) will inevitably produce a design whose structure is a copy of the organization's communication structure."_

Conway's Law tells us that the systems we create tend to mimic the environments in which they're created.
For those of you who have worked in business with varying styles or both work in industry and contribute to open source, this should intuitively make sense.
In fact, a [2008 paper from HBS](https://www.hbs.edu/faculty/Publication%20Files/08-039_1861e507-1dc1-4602-85b8-90d71559d85b.pdf) had the following to say after researching similar projects (databases, financial modeling, etc...) produced by teams with varying organizational structure:

    We  find  strong  evidence  to  support  the  mirroring  hypothesis.
    In  all  of  the  pairs  we examine, the product developed by the loosely-coupled organization is significantly more modular than the product from the tightly-coupled organization.
    We measure modularity by  capturing  the  level  of  coupling  between  a  product’s  components.
    The  magnitude  of the  differences  is  substantial – up  to a  factor  of eight, in  terms  of  the  potential  for a design  change in  one  component to  propagate  to  others.
    Our  results  have  significant managerial implications, in highlighting the impact of organizational design decisions on the technical structure of the artifacts that these organizations subsequently develop.

Rather than dissect Conway's Law for the _nth_ time, I'm going to use this article to explore some of the managerial trade offs mentioned in the HBS paper.
The rest of this piece will be a case study on one particular instance of an engineering manager (me...) working within the confines of Conway's Law.

### The Problem
The system in question is a monolithic codebase consisting of ~30 individual processes that deploy together.
The engineering organization consists of five teams, four of which primarily work in this project.
The question is how to effectively support - in the operational sense - such a system as the engineering team grows.
In the early days all of the engineers understood the majority of the system, so it was easy for them to fix bugs regardless of where they popped up.
As the number and size of the teams grew, the expectation that any arbitrary engineer had enough context to effectively troubleshoot a problem became unrealistic.

The challenge in designing a support system for the software comes from the tradeoffs between flexibility and stability. Like

### The Importance of Flexibility

