---
title: "Lexographic_permutations"
date: 2019-04-01T14:01:17-04:00
draft: false
toc: false
images: tags:
  - Algorithms
---

I've been reading a lot lately about the early days of computers & hacker culture.
Each of the books has highlighted how important having a deep understanding of the tools & hardware has been for programmers, regardless of generation.
Personally, I've been fortunate enough to spend my entire career working with relatively high-level languages like Scala, Haskell, or even C#.
Tools like those allow programmers to be extremely productive without ever really grasping the inner workings of their machine.

Because of this, and because I've never had to write low-level code under pressure, I've always had a soft spot for low level languages like C, Haskell's Core, or CIL.
I've recently started playing around with C again and stumbled on a really enjoyable algorithm.
So, without further preamble, let's talk about finding the permutations of an array.

# Finding permutations in lexographic order
First off, for those who aren't familiar, lexographic order is also referred to as "dictionary order".
This means that if you have the four strings, `bat`, `all`, `ball`, `bal` they'd be ordered as follows:
```
all
bal
ball
bat
```

That's not particularly interesting, and can easily be expressed in C using the following:
```C
int lex_compare(char* l, char* r){
    int len_l = strlen(l);
    int len_r = strlen(r);
    int smallest = len_l < len_r ? len_l : len_r;

    for(int i=0; i< smallest; i++){
        if(l[i] < r[i]) {
            return -1;
        } else if (l[i] > r[i]) {
            return 1;
        }
    }
    if(len_l == smallest && len_l != len_r){
        return -1;
    }
    else if(len_r == smallest && len_l != len_r){
        return 1;
    }
    return 0;
}
```

Having established what a lexographic order is on strings, let's get to the interesting algorithm!
The problem was writing a generator (meaning a function that yields a value until the sequence is complete) of the lexographically sorted permutations for a set of strings, skipping over any duplicates.
Let's break down the requirements here, since there are several & they're each interesting on their own.
First, how do you write a generator?
Next, how do you write an ordered generator?
Finally, how does one skip over any potential duplicates?

When I first saw this problem I thought about how you'd normally find permutations.
Consider all possible single-element arrays, then all two-element arrays created by pre-pending one of the remaining elements onto the single-element array.
Recursively repeat this process until there is an array of sets for each possible single-element array.
This implementation is pretty much untested, but the best I could come up with in a few minutes and it clearly illustrates the branching logic described above (its also much clearer than the version in `base` due to its naivete):
```haskell
-- *Lib> permutations "abc"
-- ["abc","acb","bac","bca","cab","cba"]
permutations :: (Eq a) => [a] -> [[a]]
permutations [x] = [[x]]
permutations xs@(x:rest) = concatMap (\a -> (a:) <$> permutations (filterFirst a xs) ) xs
    where
        filterFirst _ [] = []
        filterFirst a (z:zs)
            | a == z = zs
            | otherwise = z: filterFirst a zs
```

This certainly seems to give us all the permutations, but what about producing them in lexical order?
The first thought that jumps to mind is porting the `lex_compare` function above then composing a `sortBy lex_compare` call onto the `concatMap`.
That would be correct, but running a sort operation on a list in Haskell forces the full evaluation of the list, which means we'll be sticking all of the permutations in memory.
For those of you that don't happen to remember much combinatronics, the permutations for a list are _n!_, so even for a relatively small list like "abcdefghij", that will be over 3.6MM elements generated before the sort.
That doesn't bode well for this solution...

Skipping over how we'll deal with that for a second, I want to briefly mention that were we to solve this with Haskell, we can take advantage of laziness and get our generator for free!
The downside to leveraging a language-specific feature in the solution is that it obviously doesn't translate to any other languages.
That means that solutions to a problem that rely on "yeah, but Haskell's lists are lazy" are a bit underwhelming.
Don't get me wrong, laziness is a great feature, but because it's a feature of relatively few languages its good to know how to solve problems without relying on it as well.

Returning to the idea of an ordered generator, its actually possible to do this by leveraging the lexographic order.
At first, I was pretty bewildered & attempting to write an algorithm that did the following:
```
generate all permutations
sort them
use a secondary index i <= n! to track the current permutation
when i == n!, indicate the generator is complete
```
Earlier I mentioned that this has terrible space complexity, but its actually possible to do this in constant time. This blew my mind.

## The algorithm
Just like in the Haskell permutations algorithm, by first finding a trivial subproblem to solve we can then build up a full solution.
We've been talking about sets of strings, but this particular algorithm is actually a bit easier to illustrate using numbers, so let's consider the set `[9,1,2,4,3,1,0]`.
The sub-problem we're going to solve is to find the _next_ largest permutation, i.e. the next value in a lexographic ordering of all the permutations.
If you look at `[9,1,2,4,3,1,0]` and play around for a few minutes you'll find that `[9,1,3,0,1,2,4]` is the next largest permutation, after which comes `[9,1,3,0,1,4,2]`.
Subconsciously, you're probably starting from the right of the list, then working your way left until you find a number smaller than its' right-hand neighbor.
This is the number you'll need to switch with the lowest (right-most) number larger than itself.
Once that's done, you need to rearrange the numbers to the right so they're as small as possible.

Intuitively, that makes sense. But what does the algorithm look like?
In pseudocode:
```
given an array of length n.

// Find the pivot point by searching from right -> left through the array
// If the pivot crosses below 0, then the entire array has been seen &
// the current permutation is the largest posible (because all numbers are
// arranged in descending (l->r) order
pivot = n-2
while (pivot >= 0 && array[pivot] >= array[pivot+1])
    pivot--

if (pivot < 0)
    DONE

swap_target = find_rightmost_larger_than_pivot()
swap(pivot, swap_target)

// This is initially counter-intuitive, but it works because the pivot was
// found by finding the longest descending sequence adjacent to the end of
// the array. Reversing this means the smallest numbers are now closer to the
// head of the array, and therefore holding higher-order weight in the
// lexographic sort.
reverse_right_of_pivot()
```

From my perspective, this is definitely no-trival, but also a fascinating algorithm. On top of that, it allows for generating all permutations in _O(n)_ time and constant space, which is pretty impressive after the earlier _O(n!)_ experiments.


