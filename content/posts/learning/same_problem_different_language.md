---
title: "Same problem, different language"
date: 2022-02-06T06:58:17-04:00
draft: false
tags:
    - learning
    - programming
---

Different languages have different strengths and weaknesses, which makes solving certain types of problems easier or more difficult. This post explores the different levels of abstraction commonly used in Ruby vs. Haskell. Typical Haskell code uses a much higher level of abstraction, making the code terse but also difficult for newcomers to understand. On the other hand, Ruby - while not an exceedingly verbose language - is usually written with a lower level of abstraction, making it more accessible yet harder to maintain due to it's lower abstraction level. I demonstrate the different approaches these languages encourage by showing how to reverse a linked list in linear time and constant space with each of them. I'm not advocating for one tool over the other, but I hope you come away with a more critical eye towards the strengths and weaknesses of your chosen tools.

Haskell is a typed functional language that supports immutability and lazy evaluation by default. It started out as a research language and despite it's increasing popularity - although it's still niche - in industry, Haskell is still a research language at heart. The library ecosystem has decades of development behind it, and many of the libraries place mathematical abstractions at the programmer's fingertips. As a result, reversing a linked list has a simple and elegant solution that's inscrutable to anyone that is unfamiliar with the abstractions in use.

```haskell
reverseLinkedList :: [a] -> [a]
reverseLinkedList = foldl' (flip (:)) []
```

The heart of this implementation is the higher-order function, `foldl'`. `foldl` is the left-fold function. Folds accumulate a result while traversing recursive data structures. Unsurprisingly, left-folds work from the left side of the data structure to the right. That happens to be the same required to reverse a linked list. However, Haskell uses lazy evaluation by default, and `foldl` (notice the lack of a trailing `'`) is the lazy left fold. Lazy folds accumulate chains of unevaluated thunks on the call stack as each element of the data structure is "reduced" onto the resulting value - in my example each time an element is consed onto the list.

Allocating `n` stack frames uses `O(n)` memory rather than `O(1)` memory. A solution using `foldl` doesn't meet the requirements. Haskell does support immediate or "strict" evaluation using the `seq` function. There are strict implementations of many higher-order functions like `foldl` that immediately evaluate their function arguments. By convention, those functions end with a `'` or live in a `.Strict` module. In the example you'll notice I've used `foldl'` because the solution needs this behavior. I've used several other abstractions or techniques in that solution as well like `flip`, `[]` being a cons list, and pointfree style. Hopefully this gives you a good sense that Haskell's brevity comes from the deep layers of abstraction the code leverages (and that programmers need to understand).

Ruby, while also a high-level language, uses less powerful abstractions than Haskell. As a result it is both more verbose and a more approachable language than Haskell. Ruby attempts to offer as few surprises as possible to programmers. Let's take a look at the linked-list reversal solution in Ruby.

```ruby
def reverse_list(head)
  xs = head
  acc = nil
  while(!xs.nil?) do
    x = xs.next
    xs.next = acc
    acc = xs
    xs = x
  end

  acc
end
```

At 12 lines and 25 words, it is much more verbose than the Haskell solution, which has positives and negatives. Unlike Haskell, almost everything required to understand the algorithm is present in the function (`while` is the only abstraction used, and that's about as basic as there is). Using a small number of basic abstractions makes the code much more approachable. I presume anyone with some basic programming knowledge looking at the Ruby implementation can piece together what's happening without consulting additional documentation. At the same time, the more verbose code also introduces additional opportunities for errors.

I'm not arguing that one tool is superior in any way to the other, but that tools have strengths and weaknesses which we need to consider when using them. Haskell and Ruby are both excellent tools. Haskell code tends to be robust and resilient to change, but takes a long time for new developers to learn the language. Ruby on the other hand is famously accessible, but dynamic typing and it's verbosity makes maintenance over time more expensive. There's nothing wrong with either of these languages, and they're both extremely useful in many situations. My ask the next time you reach for a language or framework is to consider the second and third order impact of that choice on the problems you're aware of.



*The Haskell solution actually uses `O(n)` memory because a new cons cell is created each time an element is added to the list. The values themselves are reused, but the `(:)` is new for each. Avoiding this would mean building a reference-based linked list like the Ruby example uses.
