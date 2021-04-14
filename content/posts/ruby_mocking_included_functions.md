---
title: "Know your tools: a facepalm-worthy lesson"
date: 2020-02-05T06:06:56-05:00
draft: true
tags:
  - Ruby
---

tl;dr; A brief story of an issue I created when writing some Rails tests.
This got me considering how method calls in Ruby work, particularly the ancestor chain.
But, the issue turned out to be unrelated to inheritance.
The crux of the issue was that I'd made a mistake in understanding how a `view` in Ralis works, which led me down the wrong path while troubleshooting.

## Mocking module methods with RSpec
The other day at work I had my understanding of Ruby's `include` tested.
My mental model at the start of the day was that an `include` statement added the public functions exported by the included module to the target class, and that the Controller in Rails evaluates the View code.
That model holds up for most day-to-day programming, but the other day I ran into an issue with some tests that called it into question.

The system under test was a typical Rails app that looked something like this:
`app/controllers/foo_controller.rb`
```ruby
class FooController < ApplicationController
    def index
    end
end
```

`app/helpers/application_helper.rb`
```ruby
module ApplicationHelper
    def helper_function(user)
        call_outside_world user
    end
end
```

`app/views/foo/index.haml`
```ruby
- helper_function
Great success!
```

By default Rails controllers include not only all of the built-in Rails helper modules, but also any modules defined within `helpers` thanks to some magic implicit `include` statements.
`FooController` therefor has an implied `include ApplicationHelper` somewhere in its definition.

As I began testing my controller, I obviously didn't want them to actually interact with any of our external systems.
Enter Rspec Mocks.
Mocking out `FooController#helper_function` seemed like the right thing to do.
After all, the helper modules had all been automagicaly included into `FooController` by Rails' plumbing, so this should be simple.
So I added this at the top of my test's `describe` block:

```ruby
before :each do
    ...
    allow_any_instance_of(FooController).to receive(:helper_function).and_return(42)
    ...
end
```
If you're a more experienced Ruby developer than I am, I imagine you're cringing at the use of `allow_any_instance_of`.
That function is on its way out of RSpec, and for good reason.
While its useful in many situations, it also makes it easier to write convoluted or difficult to test code.

To my frustration, mocking that function call didn't do anything.
I poked around for much longer than I'm proud of before it dawned on me that I should try mocking out `ApplicationHelper` instead of `FooController`.
Sure enough, I saw the behavior I was looking for and my tests started passing.

## What happened?

In the movement, it was surprising that mocking out the helper module worked while mocking the controller did not.
After thinking about this for a moment though, I was reminded that `allow_any_instance_of` injects an RSpec `Proxy` in front of `FooController` anyways, meaning it intercepts any call to `FooController` _before_ the controller's implementation could handle the message.
And since I was not seeing the behavior I expected from `allow_any_instance_of`, it must be the case that `helper_function` is not being called on `FooController`.

After a bit more reflection this started making sense.
Of course the helper function wasn't being called directly from `FooController`, it was part of the view logic!
I had forgotten that Rails controllers coordinate behavior but delegate the actual rendering to `ActionView` plumbing.
Rails has a lot of magic, and sometimes its easy to lose sight/forget how all the pieces fit together.
In those cases, like I learned the other day, its important to take a step back and think through how the behaviors you see occurring fit with your understanding of the world.
Odds are its a bug in the programmer's understanding, not a framework with as much mileage as a Rails 5.x version.

And with that, I leave you to go have a chuckle at my expense.
Hopefully you also remember to check your understanding when in a similar situation too!
