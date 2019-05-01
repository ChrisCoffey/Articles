---
title: "Beware the consequences of Peak-End Rule"
date: 2019-04-29T13:24:10-04:00
draft: false
toc: false
images:
tags:
  - "management"
  - "projects"
---
At work we've recently changed how we execute software projects in an effort to dramatically shorten the feedback between work & learnings gleaned from that work.
However, as with any sort of transition, there's a body of work that has recently been wrapping up.
Amongst this work were a pair of quarter-long projects that had very different execution stories & completion states.
I'll be using these two projects (in the abstract) to explain Daniel Kahneman Et Al.'s [peak-end theory ](https://psycnet.apa.org/doiLanding?doi=10.1037%2F0022-3514.65.1.45) and how this can introduce some costly biases into project evaluation.

## A Tale of Two Projects
Two teams I'm responsible for recently wrapped up their projects, which we'll call **A** and **B** for convenience.
Team **A** was staffed by a first-time team lead and a pair of engineers.
Team **B** had three engineers and an experienced team lead.
By my estimate, project **A** was less complex but had a very strict launch date defied by an external obligation.
Project **B** on the other hand was extremely complicated from the outset, but did not have as strict of deadline or scope requirements.
While the absolute experience level of the leads on these projects was quite different, the Task Relevant Maturity (as defined by Andy Grive et al.) for both leads was quite low, albeit along different dimensions.

When it came to executing on the two projects, they followed almost opposite paths.
Project **A** started off extremely slowly.
The typical project-lead tasks of breaking work down and providing multiple solutions to a problem were all new for the team, and their output reflected this.
However, as the weeks crawled by, the team's output began increasing rapidly.
In the weeks immediately before the release, the team finally reached what I'd consider a solid TRM, and their output reflected this.
They ended up shipping their project on time, and while there were a few bumps with the launch, overall it was on par with my expectations for any new product's launch.

On the other hand, project **B** began with extensive planning and design befitting its complexity.
During that process, the lead's relatively high TRM in those areas shone through and raised my confidence that the project would proceed smoothly to launch.
Unfortunately, what really happened was that I mistakenly conflated the lead's competence with abstract planning and design with their ability to guide execution in a stack they were not particularly familiar with.
As I'm sure many of you have seen this play out before, the project quickly went off the rails when it transitioned from design to execution.
Delay after delay popped up, and the deadline was pushed several times while the scope was also cut.
Ultimately, no amount of shifting the project's definition could make up for the low TRM and my failure to effectively manage it, and we ended up shipping at ~50% over budget.

These are two very different projects with very different outcomes, yet my intuitive perception of them is extremely similar. Why?

## Its all about impressions
It turns out that Daniel Kahneman's research has something to say about this phenomenon.
The idea is called the "Peak-End Theory", and it applies _only_ to those situations with a discrete end.
The peak-end theory, or rule, basically says that a person's perception of an experience is disproportionately impacted by the most extreme sub-experience w/in that experience (i.e. peak or valley) as well as how the experience ends.
I'm sure many of us can relate to that when you think about a particularly enjoyable trip that had a really memorable moment and you got home safely without any issues.
Similarly, there's probably terrible memories about a class you've taken where you were particularly out-of-depth one day, and perhaps didn't do very well on the final.

So, why am I bringing up the peak-end rule in the context of software projects & management?
It turns out that its an extremely powerful cognitive bias that can easily cloud your perception and evaluation of a project's success.
Using my **A** and **B** projects as examples, to the uninvolved reader, it should be obvious that one was successful and one was a failure.
Yet, to this day I don't see them like that.
The scar tissue left by how project **A** was executed leaves this lingering perception that it was a "bad" project that must have failed, because otherwise why would I remember it so unfavorably?
I perceive project **B** in exactly the opposite light, somehow feeling that it must have been a better project than it was because of the positive initial impressions left by the quality of the initial design & discovery.
Personally, the fact that two projects with vastly different outcomes share the same perception in my mind is horrifying.

The reason these murky perceptions are concerning has everything to do with how success is measured.
If a team and/or individual's success is measured entirely by their manager's (my) _perception_ of how they've performed, then the psychological blind spots like the peak-end rule are important to acknowledge and plan around.

## What does success look like?
After pointing out that I'm susceptible to the same  cognitive biases that we all are, its important to keep in mind that there are several tools that can effectively combat these biases.
I'm going to focus briefly on the single most effective way I'm aware of to retain objectivity when evaluating a discrete project.
Objectives.
Specifically those set up-front at project kickoff that have measurable completion criteria.
An example of a measurable objective (admittedly its measuring the wrong thing) would be to have the team complete 10 "stories" every two weeks.
That can be easily measured, and those measurements are stable, meaning my understanding of them over time is unlikely to change.

Conversely, an objective like "make the stakeholder happy" is pretty much impossible to use.
First off, you can't measure it.
I mean, I could ask my stakeholders to take a satisfaction survey every week, but that's simply quantifying something inherently subjective (which is a separate conversation in itself).
Secondly, happiness and the perception thereof is an extremely complex and ephemeral state.
Perhaps the stakeholder had a bad commute on the day I send them the survey.
Should I really allow something like that to negatively impact the team/individual's delivery on their metric?
Obviously not.

At the end of the day, its important to set out clear expectations and some achievable success criteria at the onset of a project.
This lets us, the human managers managing humans, avoid some of the most devious cognitive biases that we're susceptible to.
That in turn lets us coach our teams more effectively, and provide actual data to our employees, which they can use to improve their own individual effectiveness.
