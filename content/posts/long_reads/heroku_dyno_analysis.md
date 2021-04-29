---
title: "Understanding variability in Heroku dyno performance"
date: 2021-04-15T16:07:29-04:00
draft: false
tags: ["performance", "hosting"]
---
Heroku is a great platform if your app conforms to their expectations, but their dyno abstraction is somewhat leaky.
It is surprisingly easy to deploy an application that behaves differently than you'd expect despite their documentation's warnings about shared CPUs.
In this post I share some research on the performance/behavior of their various dyno classes and how I think about selecting dynos for different workloads.

If you're familiar with Heroku's platform, I suggest skipping ahead to [exploring CPU-intensive workloads](#exploring-cpu-intensive-workload-variability).
The information in this post comes from a combination of my experience using Heroku and their documentation.
I do not have any specific or privileged knowledge of _how_ Heroku actually works, nor have I ever worked at Herkou.

### Platform overview

Heroku is one of, if not _the_, original platform-as-a-service vendors.
The platform was originally designed to host Ruby on Rails applications that conformed to the [12 Factor App](https://12factor.net/).
As long as I've been using the platform it has had strong opinions about how applications should be be architected, and offered an incredible developer experience if you say within the bounds.
Heroku is essentially a container orchestration platform, and while they started off building containers automatically based on Git pushes - albeit for a limited number of languages- , these days they also offer direct support for Docker containers.
As a result, you can deploy any stack you want.

While they may be unfamiliar initially, their in-house abstractions map nicely onto more-familiar - or at least more thoroughly documented - concepts from Docker.
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
Heroku allows horizontally scaling applications and makes a best effort to allocate different dynos for the same application into different availability zones, providing some "free" redundancy.
Additionally, because they have a large cluster of machines up and running at all times, allocating the marginal dyno is typically extremely fast because it doesn't involve allocating an any additional nodes to the cluster.
In other words, the CR is able to provide fast startup times for new dynos because the majority of the dynos running are sharing time with dynos from other customers.
I say _majority_ rather than all dynos because after a certain price tier within the CR dynos are allocated on dedicated hardware.
Whether the machine itself is dedicated to the dyno or whether CPUs are pinned to a particular container is an implementation detail of the platform that I'll explore later.

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
That could be a great business decision, but its important to note that many PaaS providers build their orchestration infrastructure on top of cloud instances provided by vendors like AWS or GCP.

For multi-tenant nodes (also known as "timeshared"), this story gets more complicated and scheduling priority becomes very important.
In a timeshared system the CPU is shared between many processes, with each process getting _some_, but not necessarily equal CPU cycles.
For PaaS providers, its in their best interest to cram as many containers as possible onto a given node in the cluster in order to maximize their profit.
So something like Heroku's CR dyno manager presumably looks at node utilization and tries to maintain the highest _safe_ usage rate across each node in the cluster.
As a result, containers running on those nodes need to contend with each other for resources, and their workloads can impact each other.
This dramatically increases variability in CPU bound workloads.

Heroku has multiple timeshared offerings (`free`, `hobby`, `standard-1x`, `standard-2x`) providing different performance characteristics depending on the tier.
As a result, lower tiered processes on the same cluster node receive less processor time than their more expensive peers.
I'm unsure of the exact mechanism the Heoku uses to differentiate scheduling, but Docker allows passing memory & cpu restrictions to `Docker run`, so I imagine Herkou uses some combination of `setpriority()` and something like `ulimit`, rather than implementing something bespoke.

### Exploring CPU-intensive workload variability

This post was inspired by highly variable response times in services running on shared Herkou dynos, particularly when parsing JSON.
Parsing large blocks of JSON - multiple mB - require translating raw bytes into in-memory data structures, which in turn requires many CPU cycles to move data back and forth from main-memory and perform the parsing logic.
On a crowded shared Herkou node, regardless of whether you're running a `free` or a `standard-2x`, you're going to see a lot of variance in this type of workload.
Unfortunately, I couldn't find anything describing what was actually going on here.

On a certain level, not understanding what happens beneath Herkou's abstractions is a feature rather than a bug.
But, in the interest of uncovering a few more details, I ended up [benchmarking](#benchmarking-heroku) Heroku with a CPU intensive workload.
I describe the benchmark in more detail at the end of this post, but essentially it preformed 10k JSON deserializations for a large JSON file on each size dyno and collected some stats about them.

Each point in this scatter plot represents one batch of 100 JSON deserializations.
The `x` axis represents median duration and `y` represents the variance within a single batch as measured by the gap between median and p90 parse times.
The size of each point increases as the p90 duration for a sample increases.
Taller cluster height indicates a wider variation between the median and p90 deserialization time; in other words how fat the tail for this group of samples was.
As clusters widen, there is more variance in the median duration.

{{< heroku_experiment_viz >}}

As you can see, there are clear difference between the shared & dedicated dyno sizes.
That comes as no surprise, but it was interesting to see that the fastest `free` samples were faster than the slowest `hobby` or `standard-1x` dynos.
I had assumed that `free` were relegated to their own extremely cheap underlying instance type, but it appears that may not be the case (more on this in a moment).
Otherwise, I was also surprised to see that the paid+shared dyno classes - `hobby`, `standard-1x`, `standard-2x` - blend together to the degree they do.

The benchmark and visualization illustrate more or less what Heroku's documentation says about the different dyno classes; `free`, `hobby`, and `standard-1x` all have the same degree of "CPU share", which seems to correspond to the width of the clusters.
`standard-2x`, with its double CPU share, has a tighter cluster, but still exhibits high variance.
Then there are the dedicated instances with extremely tight clusters of small points, indicating consistently quick performance.

The following illustration shows how the average variance changes based on dyno type.

{{< heroku_variance_viz >}}

There is about an order of magnitude difference in the variance between a `perform-l` and the shared dynos.
Granted, that difference amounts to ~45ms which is likely just noise for many workloads.
And at (at least) 10x the price, a `performance-l` is difficult to justify for anything besides a professional application.

#### Behind the abstraction

After observing the benchmark performance across dyno classes, it's worth asking what the underlying AWS instance types are for each of the dyno classes.
In particular, were `free` dynos running on the same instances as paid dynos?
Did a dedicated dyno in a `performance` class have its own AWS instance, or were they also clustered, but in such a way that there were always CPUs available for them?

Thankfully, because Linux containers are essentially sandboxed apps on an underlying kernel, its possible to poke around a bit.
Launching a one-off dyno of each instance class via `heroku run bash --app <app here> --size <dyno class>` makes it trivial to extract some basic information about the underlying instance.
I initially checked `uname -a` for each dyno class, and found all of them running the same version of AWS linux.
Nothing surprising there.

Next up was taking a look at `/proc/cpuinfp` and `/proc/meminfo`.
The following table lays out the results as of April 2021:

Dyno class | Num cores   | Core type   | Memory
--|--|--|---
free | 8 core | Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz | 64GB
hobby | 8 core | Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz | 64GB
standard-1x | 8 core | Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz | 64GB
standard-2x | 8 core | Intel(R) Xeon(R) CPU E5-2670 v2 @ 2.50GHz | 64GB
performance-m | 2 core | Intel(R) Xeon(R) CPU E5-2680 v2 @ 2.80GHz | 4GB
performance-l | 8 core | Intel(R) Xeon(R) CPU E5-2680 v2 @ 2.80GHz | 16 GB

Turns out that **all** shared CPU dynos run on the same instance type.
That actually makes a lot of sense from an infrastructure management perspective, but I was still surprised to see that `free` dynos run on the same instance type as paid dynos.
This doesn't mean that `free` dynos are necessarily neighbors with paid dynos though - Heroku could configure the dyno manager to label some cluster nodes as `free` and others as `paid`.
That would prevent `free` dynos from impacting the performance of paid dynos, but this is just speculation, I have no idea if Heroku actually does this.
Additionally, the `/proc/cpuinfo` confirms each performance dyno runs on its own dedicated instance.

Armed with the instance specs, it is straightforward to lookup the underlying AWS instance type.
The shared cpu dynos appear to run on storage optimized instances.
That initially puzzled me, but it actually makes a fair bit of sense when remembering that Herkou is running Linux containers.
Each container consumes a relatively limited amount of memory, but could consume several GB of space on disk.
So if you wanted to pack as many containers onto a machine as possible, you'd want something that could store a lot of decompressed images.

Performance dynos unsurprisingly appear to run on compute optimized instances, exactly what Heroku bills them as.

### What it all means

By this point two things are clear.
First, the shared vs. dedicated dyno options at Heroku have vastly different performance profiles.
These differences in performance are less about per-core speed than they are about the variance.
Secondly, while dynos within the same "tier" demonstrate different performance characteristics from one another, they are not significant on a per-core level.
The inter-tier differences come from memory and core count, which isn't particularly surprising.

My hope is that by providing you with a deeper understanding of how Heroku's different dyno classes perform - albeit in a contrived benchmark - you'll be better able to evaluate which one is the best fit for your application's workload.
For example, if you're running a webserver with a fairly low memory footprint that mostly performs CRUD, an auto-scaled cluster of shard-CPU dynos is probably the most cost-effective solution.
On the other hand, if the application provides middleware on the critical path for a frontend server you likely care a lot about having consistent performance, so one of the dedicated dynos would be a better fit.
Unfortunately Herkou's documentation doesn't illustrate just how divergent the behavior of these two classes are, so I've had to learn the hard way.
Hopefully this post helps you avoid most of my mistakes around sizing dynos to application needs.

##### Benchmarking Herkou

The benchmark used for this experiment was inspired by the behavior observed on production applications across several languages.
I'd been aware of the variability in response times for a long time, but it wasn't until upgrading a Rails app from shared to dedicated dynos and watching the variability in p99 latency dramatically drop that I began wondering about the exact behavior.
That led me to write a benchmark to trigger a sustained CPU-intensive workload on Heroku dynos.

The benchmark is simple, consisting of a Node app that loads and parses a 5MB JSON file in a loop.
It performs 100 iterations per-request and returns some statistics about the batch of parsing performed.
I also experimented with an empty loop, but found the JSON to be a more idicative workload to the issues I've experienced in production.

The benchmark data used for this analysis was collected by running 100 requests against each dyno size and aggregating the results.

Things I did not do:
1. Run multiple tests per-dyno class
2. Vary the time of day
3. Control for garbage collection

All of those are interesting areas to explore in the future, if warranted.

The code is [on Github](https://github.com/ChrisCoffey/tail-latency-test).

{{< pretty_tables >}}
