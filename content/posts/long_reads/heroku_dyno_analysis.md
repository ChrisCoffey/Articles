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
The main reason to prefer commodity hardware over the more exotic machines used for high-performance clusters is their cost; cloud vendors purchase a variety of relatively inexpensive machines & abstract away the differences between them.
As a user of cloud machines, you're typically buying access to a virtual machine running atop some of this commodity hardware - although many vendors have begun offering bare-metal instances.
That's great, but it does mean that there is some variability in the machine's performance because of variations in the underlying hardware.
VMs running on older hardware may perform differently than those running new hardware, even if they're they same instance class.
Plus, the processes will be running on a VM rather than bare metal, so there will be an imperceptible (for most applications) performance hit from that.

Using cloud machines rather than hosting your own is making the decision that the increased variability in machine performance is worth the increased ease with which instances are provisioned and managed.
Choosing to use a PaaS rather than an IaaS is like making that decision twice.
Not only are you choosing to outsource managing the physical machines to a cloud provider, you're also choosing to outsource managing the cloud compute resources.
That could be a great business decision, but its important to note that many (all?) PaaS providers build their orchestration infrastructure on top of cloud instances.
For a dedicated instance in something like Herkou's CR, this doesn't have much of an impact because the container in question is given the full resources of the machine - after accounting for cluster daemons and whatnot.

For multi-tenant nodes (also known as "timeshared"), this story gets more complicated and scheduling priority becomes very important.
In a timeshared system the CPU is shared between many processes, with each process getting _some_, but not necessarily equal CPU cycles.
For PaaS providers, its in their best interest to cram as many containers as possible onto a given node in the cluster in order to maximize their profit.
So something like Heroku's CR dyno manager is going to look at node utilization and try to maintain the highest _safe_ usage rate across each node.
As a result, containers running on those nodes need to contend with each other for resources, and their workloads can impact each other.
This dramatically increases variability in CPU bound workloads.

Providers like Heroku that have multiple timeshared offerings (`free`, `hobby`, `standard-1x`, `standard-2x`) provide different performance characteristics depending on the tier.
That means lower tiered processes on the same cluster node will receive less processor time than their more expensive peers.
I'm unsure of the exact mechanism the Heoku uses to differentiate scheduling, but Docker allows passing memory & cpu restrictions to `Docker run`.
I imagine Herkou uses some combination of `setpriority()` and something like `ulimit`.

### Exploring CPU-intensive workload variability



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
