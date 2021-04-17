---
title: "How to think about Heroku dyno performance"
date: 2021-04-15T16:07:29-04:00
draft: true
tags: ["performance", "hosting"]
---

Heroku is a great platform if your app conforms to their expectations, but many of their abstractions are leaky.
It is surprisingly easy to deploy an application that behaves differently than you'd expect, although their documentation does warn about this.
In this post I explain how I think about Heroku's abstractions.
I also share some research on the performance/behavior of their various dyno classes and my recommendations for which classes to select vs. avoid.

### Platform overview

Heroku is one of, if not _the_, original platform-as-a-service vendors.
The platform was originally designed to host Ruby on Rails applications that conformed to the [12 Factor App](https://12factor.net/) approach to development.
As long as I've been using the platform it has had strong opinions about how applications should be be architected+deployed, and offered an incredible developer experience if you say within the bounds.
Heroku is essentially a container orchestration platform, and while they started off building containers automatically based on Git pushes - albeit for a limited number of languages- , these days they also offer direct support for Docker containers.
As a result, you can deploy any stack you want.

While they may be unfamiliar initially, because Herkou's platform is effectively container orchestration, their in-house abstractions map nicely onto more-familiar Docker concepts.
A new Git push creates what's called a [Slug](https://devcenter.heroku.com/articles/platform-api-deploying-slugs), which is effectively the same thing as a Docker image.
Both slugs and images are compressed tarballs containing the files necessary to run a particular command on a Linux kernel.
Unlike Docker images, which consist of many compressed layers stacked on top of one another, a slug does not have layers.

When you run a Docker image as a container, the image is unpacked by a Docker host and executed.
By default, Docker is a single-machine tool, so running containers on a cluster of machines requires an orchestrator like Docker Swarm or Kubernettes.
Part of Heroku's value proposition to developers is that they handle all of the orchestration & cluster management via their dyno manager.
Like other orchestrators, the dyno manager is responsible for container placement and management - making sure dynos restart after a crash, have their log drains attached, etc...

Within Heroku, there are two distinct runtimes: Common Runtime and Private Spaces.
The Common Runtime (CR) is a multi-tennant cluster running in AWS `us-east-1` or an AWS EU zone.
Private Spaces (PS) provides stronger isolation guarantees by essentially being a VPC within one of 8 different AWS regions.
The two runtimes are quite different and optimize for different usecases.
CR is intended to be highly responsive to creating new applications and dynos, while PS is meant for longer-running processes that can afford slower startup times.
All of my experience is with CR, and that is what I'll be referring to as Heroku throughout the remainder of this post.

As a multi-tenant environment, Heroku's CR maintains a sizeable cluster of machines in AWS which it uses to allocate new dynos as necessary.
Heroku allows horizontally scaling applications and makes a best effort to allocate different dynos for the same application into different availability zones, providing additional some "free" redundancy.
Additionally, because they have a large cluster of machines up and running allocating the marginal dyno is typically extremely fast because it doesn't involve allocating an any additional nodes to the cluster.
In other words, the CR is able to provide fast startup times for new dynos because the majority of the dynos running are sharing time with dynos from other customers.
I say _majority_ rather than all dynos because after a certain price tier within the CR dynos are assigned to dedicated hardware.
Whether the machine itself is dedicated to the dyno or whether CPUs are pinned to a particular container is an implementation detail of the platform.

#### Ramifications of timesharing in the cloud

Cloud computing is all about running giant clusters of commodity hardware and renting time on them to users.
The main reason to prefer commodity hardware over the more exotic machines used for high-performance clusters is their cost; cloud vendors are able to purchase far more machines & abstract away the differences between them.



- Contrast with running EC2 or ECS
  - vCPU depending on instance size
  - Cloud computing all about commodity hardware
    - As a result, actual machines often vary a bit and it is normal to see that variation leak through to instances occasionally
      - This is the "bad instance" you'll hear about sometimes
  - Different classes of Dynos with different cost points & performance
    - free vs. paid vs. perf as three "tiers"
      - Some features unlock at transition from free -> paid, and others at hobby -> standard.
      - But tiers are mostly about performance
    - Most classes on common runtime are on shared vCPUs
    - How much does being on a shared vCPU hurt your app's performance?
- Brief foray though how timesharing machines work
  - Many VMs/ containers running on a machines
  - Sharing memory, bus, and CPU time
  - Scheduler allocates time with CPU
    - When scheduled, needs to reload context from memory into the caches, then pick up work where it was left off
    - Some workloads this can be really expensive, particularly when they're CPU+Memory intensive like parsing a big JSON objects
    - Cycled out once the process' timeslice elapses. Must use preemptive multitasking to ensure approximately "fair" resource usage
      - sidebar w/ bit on cooperative vs. preemptive multitasking?
- My experiment
  - Explain the situation at work where we had terrible long-tail performance with CPU-heavy workloads
  - Experiment design:
      Goal is to visualize what,if any variation there is bewteen dyno classes
      Minimal benchmarking application
        Ships with a large blob of JSON
        Has endpoint to decrypt it
        Returns statistics about 100 runs
      Run 100 calls on each dyno class
        - Did not vary by time of day or onto multiple dynos. Could be good future work though
- Interpretation of results
  - Cluster density per-dollar/month?
    - Don't get into actual speed per-dollar
  - Which workloads are the best for different types of applications?
    - If your workload is largely IO bound, is there a reason to pay-up for a Perf-M?
    - Is there any reason to select a Perf-M over a Perf-L for compute-heavy workloads?
      - Density per-$, along with vCPU & RAM
- Mention that we ended up going w/ larger instances for reasons unrelated to cluster density, but we saw our long-tail latency disappear
- With that in mind, happy capacity planning
