---
title: "Mocking Included Module Methods"
date: 2020-02-05T06:06:56-05:00
draft: true
tags:
  - Ruby
---

tl;dr; A brief story of an issue I created when writing some Rails tests.
This got me considering how method calls in Ruby work, particularly the ancestor chain.
But, the issue turned out to be a bit unrelated.
There's a surprise ending, but the crux of the issue was that I'd made a mistake in understanding how a `view` in Ralis works.

## Mocking module methods with RSpec
The other day at work I had my understanding of Ruby's `include` tested.
My mental model at the start of the day was that an `include` statement added the public functions exported by the included module to the target class.
That model holds up for most day-to-day programming, but the other day I ran into an issue with some tests that called it into question.

The system under test was a typical Rails app that looked something like this:
`app/controllers/foo_controller.rb`
```
class FooController < ApplicationController
    def index
    end
end
```

`app/helpers/application_helper.rb`
```
module ApplicationHelper
    def helper_function(user)
        call_outside_world user
    end
end
```

`app/views/foo/index.haml`
```
- helper_function
Great success!
```

By default, Rails controllers include not only all of the built-in Rails helper modules, but also any modules defined within `helpers`.
`FooController` therefor has an implied `include ApplicationHelper` somewhere in its definition.

As I sat down to write some tests for my controller, I obviously didn't want them to actually interact with any of our external systems.
Enter Rspec Mocks.
Mocking out `FooController#helper_function` seemed like the right thing to do.
After all, the helper modules had all been automagicaly included into `FooController` by Rails' plumbing, so this should be simple.
So I added this at the top of my test's `describe` block:

```
before :each do
    ...
    allow_any_instance_of(FooController).to receive(:helper_function).and_return(42)
    ...
end
```

To my frustration, mocking that function call didn't do anything.
I poked around for much longer than I'm proud of (felt like at least an hour) before it dawned on me that I should try mocking out `ApplicationHelper` instead of `FooController`.
Sure enough, I saw the behavior I was looking for and my tests started passing.

## Remembering the ancestor chain

Why didn't mocking out the function on `FooController` work?
After all, `include` was implicitly used, so the functions defined in the helper module should have been implicitly inserted right into the contrller class.
At least, that was the mental model I was working under, and it seemed to be backed up by most discussions of Ruby's `include` keyword.
Unfortunately, all of those discussions are oversimplifications that gloss over how method calls in Ruby actually work.

Everything in Ruby is an `Object`, and objects can have methods attached to them.
In true object-oriented style, objects communicate with eachother by sending messages.
Ruby objects all have a `send` method, which implements actually finding message handlers and evaluating them.
But why did I jump from talking about methods & functions to messages & handlers?

In Ruby, because everything is an object with message passing capabilities, the dot syntax - `foo.bar(baz)` - we're all familiar with is actually syntacic sugar that internally leverages the capabilities of `send`.
`send` effectively attempts to pattern match the name of te message - i.e. method name - with a method (handler) defined on the receiving object.
If a handler is found it is evaluated and the result is returned to the caller.

That means if `include` were to add the functions defined in the included modulek directly as methods on any insatnce of the including class, my `FooController` mistake would have actually worked.
Alas, that's now actually how `include` works.
Instead of directly adding additional object methods onto the receiving object, the module's object - remember, **everything** is an object in Ruby -- is inserted into the *receiver chain*.
When calling a method on `FooController` for my included module, what actually happens is that the runtime recognizes that the class doesn't contain `helper_function`.
Rather than giving up immediately, it looks to the next ancestor and checks if it can handle a `helper_function` message.
If so, it will evaluate it & return.
It not, it continues checking up the chain until it either finds an object that can handle the message or it `Object` raises `method_missing`.

- Point out how `allow_any_instance_of` works, and that it grants any class the ability to handle a message
- But why wasn't it getting called?
- FooContorller wasn't receiving that call!

## The twist ending
- Talk through FooController doesn't receie the call because the helper is evaluated in the view, not the controller!
- Talk about how HAML view rendering works. May delve into action view as well, if necessary
