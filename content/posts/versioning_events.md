---
title: "Versioning_events"
date: 2019-03-11T17:03:16-04:00
draft: true
toc: false
images:
tags:
  - untagged
---

- What I know
    - Event streams are immutable, and therfore should be considered as ledgers.
        - Updating a ledger simply isn't done, instead new offseting events are applied. This supports mutation, but what about modifying the very structru of the events?
    - In a system like Trellis where for a long time the events were extrmely stable, we could get away with modifying the old events.
        - This doesn't scale to a large team (need to process events on startup, or on some sort of cycle)
        - Centralizes the responsibility in the store (is this bad?)
    - Different paradigm from adding a column to a schema
        - that naturally modifies all of the data at rest. An event stream is a different concept that takes different tools
        -
    - There are other ways to version like pushing the versioning to the consumers
        - layered wrappers
        -  ???
    - Versioning implies a linear path from v1 -> vn
        - Any event Vx should be convertible into Vy, iff x <= y

# Points from the book

### The way I've been thinking about schemas
    - A single update to the data is the equivalent to updating all of it. If the stream changes its shape over time, I.e. if the following time sequence holds, then the benfits of
    immutability go out the window.
        ```
        t0:  Store event x, with index 100
        t1: find events <= 100 where x == x
            - returns x
        t2: modify schema of x to y
        t3: find events <= 100 where x == x
            - returns nothing
        ```
    - If an event isn't convertible into a newer version of it, then the newer version is likely a new event entirely
    - Upcasting, or applying a chain of functions to automatically convert every incoming event from Vx -> Vy causes major problems for a distributed or multi-stage deployment
        - Multiple consumers may be reading different versions of the event
    - doubl writing is another option. I.e. write _every_ possibly deployed version whenever an event is published.
        - Falls down when replaying the stream into a projection, because the contents of the projection will shift with each replay
    - the state hydrated from the stream to validate a command is still a projection!
        - Very good to keep in mind


### Weak schemas (Or how I've actually been doing a lot of this)
    - JSON as a bridge between schema worlds
        - Push the translation across versions into the mapping from JSON -> Type
        - In this world, renaming is a breaking change
        - removing a field is a breaking change
    - Another option is to make many new/non-core fields optional
    - Wrappers are actually a hidden blob of JSON & the machinery to get/set fields in it
        - Provides lots of flexibility, at the cost of some additional complexity
        - This could help address some of the serialization issues in Trellis
        - Look into non-aeson de-serializers that are more memory friendly?
            - What would this look like?
    - Late-binding.. What is this?
    -
### Serving Event Streams
    - Atom as a protocol for publishing event streams
        - RFC 5005
        - Using HTTP's "Accept" headers to specify the event versions that the client can accept
            - This is an intersting model for disparate consumers. But it does assume that the publisher can control the version of the event returned.
                - Trellis cannot do this, since it has no visibility into the event bodies, but it does know their versions
            - The key to this appraoch is that the client specifies the format they would like, not the server dictating it
    - Consider a model where subscribers register with a "publisher".
        - can have many publishers, and many subscribers.
        - Subscribers track version numbers, as do the publishers
        - PUblishers take a pool of subscribers & send events to them
            - Use some central storage to ensure that they're routed properly, and not double-sent
        - Flips around the "take everything" stream model and instead pulls them in via topic endpoints
            - subscriber provides a listener endpoint & the event types it would like sent to that endpoint
            - Sender tracks max versions its sent to that endpoint. Subscriber can do the same if it likes
        - sender protects the endpoint with a circuit breaker
    - Suggestion that the provider publishes with a specific version is interesting.
        - Avoids issues with the consumer receiving newer versions than it can handle.
        - But pushes lots of complexity into the provider. Not sure if this is worth it.

### General Versioning concerns
    1) Don't apply mutations when hydrating a projection from events
    2) Coupled projections is dangerous
        - Think of all the service's reliance on Gourd
        - Instead, each service could simply pull in the events it needs at that point in time as well
    3) Rebuilding projectsions should be isolated to only the service where hte projection is hosued. It should 100% not call out to another service for *anything*!
    4) Commands & events are not the same thing. If a system is actually event sourced for commands & events then its important to remember not to combine semantically different concepts into a single event
