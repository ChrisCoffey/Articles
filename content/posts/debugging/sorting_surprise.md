---
title: "Sorting surprise"
date: 2020-02-12T07:43:38-05:00
draft: false
tags:
    - Ruby
    - SQL
---

#### tl;dr;

Checking your invariants matters.
It's easy to write code that violates an invariant if you've forgotten to verify it.
When in doubt, make the constraints and assumptions you are working within explicit rather than implicit.
This will help future-you avoid all sorts of pain.

### The Classic Missed Invariant

Have you ever seen a test fail in CI or a function fail in production only to have a teammate (or yourself) declare "... but it works on my local!"?
These errors generally come from some sort of assumed implicit invariant like "network calls only take 1ms", "there will only be 1,000 records in the Foo table", etc...
People often don't consider things like that invariants, but if we take *invariant* to mean *an assumption about the data/system that must remain true at all times for correct behavior*, then they most certainly are.
The problem with many assumptions about systems and their input is that they're very difficult to test in most situations.

The data volume issue mentioned in the previous paragraph is a classic example.
An algorithm written to work on the hundreds or thousands of objects found in the developer's environment fails when run against the hundreds of thousands or millions of objects in another environment.
In this case, the invariant assumed by the code's developer is something like *We have 10k signups a day. That is unlikely to change suddenly, so I can safely load all of the the into memory for this job*.
And that reasoning is fine, until the day that their app gets featured on Wired and suddenly they have 150k signups in a day.
I'm not advocating that all software is written to handle 15x spikes in load - that would be ridiculously expensive -, but I am trying to point out how easy it is for our underlying assumptions to become undocumented invariants in our code.
Undocumented invariants are often the most confusing/painful to address when they're broken specifically because there is almost never a comment or test illustrating that the developer assumed there would only ever be 10k daily sign ups.

### A Real World Example

Data volumes are one of the more obvious examples of implicit assumptions and their impact on the forward-correctness (likelihood that the software continues to be correct in the future).
Let's consider a more subtle example one of my teams ran into recently.

The team had recently added a new widget to our web app that displayed a collection of data the logged-in user had indicated interest in.
As the user indicated they were interested in an additional `FooBar`, it would appear in their collection with various details and analysis associated with it.
Internally, the feature uses a typical `ActiveRecord` query to retrieve all of the `FooBar`s the user is interested in:

```ruby
foobars = current_user.foobars.where(status: STATUSES::INTERESTED).map(&:foobar_id).uniq
```

The feature launched about a week prior and had been stable.
It had plenty of test coverage, including tests verifying the behavior immediately after users indicate interest in a new `FooBar`.
All of the tests worked locally and in CI.
And yet, a week later this innocuous code became the source of a head-scratching test failure that consumed hours of time debugging.

The problem began when the following line was added to the `add_foobar` function:
```ruby
def  add_foobar(args)
    # verification and stuff
    foobars << Foobar.create(args)

    side_effect(num_foobars: foobars.lenth)
    # ^ The new line
end
```
Now the test case for indicating interest in `FooBar`s was failing on CI, but passing locally.
After initially assuming that the failing test case *must* be in the complex side-effect logic, we isolated the source of the issue to the `foobars.length` call.
Leaving that line in would cause a failure in CI, but commenting it out or hardcoding `num_foobars` passed.
The test would consistently pass locally.

At this point the test logic itself came under deeper scrutiny, and we noticed that the test had an interesting assumption coded into it. Take a moment and see if you can spot it:
```ruby
context "Broken Foobar test" do
          before :each do
            user.foobars.add_or_move(
              foobar_id: ["d259408b-b428-4bc1-91c5-ea5ed598ac65"],
              status: STATUSES::INTERESTED
            )
            visit dashboard_path
          end

    ...
          it "handles newly-added missing foobr state " do
            non_default_foobar = find_all('.foobar-item .title')[0].text
            click_on non_default_foobar

            within(first('.foobar-section')) do
              expect(page).to have_content("We're currently updating the data for this foobar.")
            end
          end
    ...
        end
```

The hidden assumption - i.e. implicit invariant - that broke this test is hiding behind the `..)[0]` indexing operation.
For that code to work correctly, it must assume that any newly-added `FooBar` appears at the top of the list of `FooBars`.
If you scroll back up to the ActiveRecord query however, you'll notice that no sorting is applied to the `foobars` collection.
This means the ordering is undefined behavior, resulting in a different sort order in CI versus a developer's machine.
Thankfully, that kind of undefined behavior is trivial to guard against by adding the missing sort to the AcitveRecord query.

### The Takeaway(s)

Hopefully the example above - despite being brief -  provides an easily relatable example of how easy it is for us as software developers to forget to encode all of our assumptions into our code.
When we assume things about the input data or behavior of the system without also adding logic or tests that confirms this holds, we set ourselves and our teammates up for crashes, painful debugging sessions, and lots of stress.
So try to keep this in mind the next time you think "**X** will never happen".
That doesn't mean guard against and recover from every possible situation, but it does mean that you need to think through why the specific code you've written is correct for the problem you're solving and the conditions that make this correct.

And finally, its great that this was caught by the tests rather than breaking for our users!
