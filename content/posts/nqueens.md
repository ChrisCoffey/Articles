---
title: "Algo Study: Evolving N Queens"
date: 2019-06-10T13:23:53-04:00
draft: true
toc: false
images:
tags:
  - algorithms
  - data structures
---
# The problem at hand
Welcome to "algorithm study", a fancy name for my fiddling with solutions to classic problems in computer science.
Many of these problems will be NP-Complete or NP-Hard, so while there may be no polynomial solution, its still often possible to create reasonably performant solutions for small values of `n`.
The series will work through things like path finding, Sudoku solvers, N-Queens, and others in an iterative fashion.
Starting from the most naive implementation I can think of through the most performant, I'll share the steps and evidence used to tune the algorithms at each stage.

## N-Queens
To kick things off, let's take a look at the N-Queens problem.
Originally formulated in **provide the year here** by **provide person here**, N-Queens asks for an arrangement of `N` queens on an `NxN` chessboard such that no queen can capture another if the movement rules from chess are followed.
From that problem there are other adaptations, like the N-Rooks (using movement rules for a rook instead of queen), or N-Queens Completion.
N-Queens Completion, or finding _all_ valid arrangement's for an `NxN` board, is what we're actually going to explore in this post.

### A naive implementation
When I first considered the N-Queens problem, it quickly occurred to me that I could implement it as a filtered list of all possible `NxN` permutations.
I chose to ignore the obviously terrible permutations that have more than one queen per-row, which allows me to consider a permutation as `N` random length-`N` lists.
That nicely breaks down into two distinct sub-problems: filtering the set of all permutations and generating the set of all permutations.
Before diving into the details of implementing this solution, let's first consider just how good or bad this solution may be.

As outlined above, we'll start by generating all possible permutations of an `NxN` grid, such that there is only a single queen per-row.
That means there are `N^N` members of our set, which is not particularly attractive.
As a concrete example, for an 8x8 chessboard that's close to 17 million permutations, perfect for establishing a baseline implementation!
This scales as poorly as you'd expect:
![Such a big number](resources/_gen/images/curve.png)
No really, this scales **extremely** poorly. 20^20 is a 27 digit number, or about 104 million billion billion...

Now that the basic performance has been established its time to explore the algorithm itself at a high-level.
```haskell
newtype SparseMatrix = [(X,Y)]
type Board = SparseMatrix

solutions :: Natural -> [Board]
solutions = filter isSolution . allBoards

isSolution :: Board -> Bool
isSolution board =
    -- Ignoring the pesky implementation of specific operations on a Board.
    -- Trust that these functions check for the presence of at most one True in each column + diagonal
    colsValid board &&
    diagonalsValid board
    -- allRowsValid is not necessary due to how permutations were constructed.

-- Ensures each row is used only once, but that all possible orders are produced
allBoards :: Natural -> [Board]
allBoards = sparsePerms . rowsOfLengthN

sparseRowPerms :: Natural -> Natural -> [(X, Y)]
sparseRowPerms col row = [(X x, Y row) | x <- [0..col -1]]

sparsePerms :: Natural -> [Board]
sparsePerms n =
    toSparseMatrix <$> perms rowPossibilities
    where
        rowPossibilities :: [[(X,Y)]]
        rowPossibilities = sparseRowPerms n <$> [0..n-1]
        toSparseMatrix = ...
```
There's a bit of hand-waving around the functions for manipulating the boards and what exactly a `SparseMatrix` is, but otherwise this is an extremely straightforward algorithm.
Unfortunately, as mentioned above its extremely slow.
Some of that is certainly just because of how I implemented it, but here's a profile from an example run on an 8x8 board using this algorithm:

```
COST CENTRE                            MODULE                    entries    %time %alloc

  main                                 Main                           0    100.0  100.0
   nQueens                             NQueens                        1    100.0  100.0
    isSolution                         NQueens                 16777216     78.8   67.4
     isSolution.check                  NQueens                 16777216      0.1    0.2
      ...
```
You'll notice that the `isSolution` filtering function is called a whopping 16777216 times, which happens to be 8^8.

The underlying `SparseMatrix` data structure is designed to represent a matrix with mostly null values only as the collection of points that are set, specifically to reduce unnecessary allocations.
But, despite that reasonably efficient data structure, the algorithm itself is doing a _lot_ more work than necessary.
That extra work occurs because the implementation of `sparsePerms` does not guarantee that each column only contains a single queen.

For example, if I generate all permutations for a 2x2 grid we'll end up with the following four matrices (it just so happens there is no solution for N=2):
```
X .     X .
X .     . X

. X     . X
X .     . X
```
Its possible to tweak the algorithm such that every permutation automatically satisfies the n-rooks problem, mostly by switching over to a theoretically less-efficient data structure.
(To be clear, its possible to implement the following using a `SparseMatrix` as well)


### A much better implementation, changing the data structure
- Same permutation approach, but with a matrix rather than linked lists
    - Decided upon because of the time spent in list operations on the naive implementation
    - Talk about the overhead list nodes introduce
        - Advantages and disadvantages of a Linked List (separate post?)
- Implementation details:
    - Still O(n!)
    - Faster indexing & diagonal derivation algorithms
        - Talk about the differences between the matrix implementaiton chosen (backed by a single Vector) vs. a linked list
Alright, so we just came up with a solution to n-queens completion, an NP-Hard problem.
Pretty exciting stuff!
But our solution ran in O(n^n), which is abysmally slow.
I promised that we could do better just by switching the data structure, i.e. stick with our "generate all permutations and filter" approach.
What's the trick?

If we switch away from a `SparseMatrix` to representing our board as `[[Bool]]` the implementation becomes
```haskell
type Board = [[Bool]]

solutions :: Natural -> [Board]
solutions = filter isSolution . allBoards

isSolution :: Board -> Bool
isSolution board =
    -- Ignoring the pesky implementation of specific operations on a Board.
    -- Trust that these functions check for the presence of at most one True in each column + diagonal
    diagonalsValid board
    -- allRowsValid and allColsCalid are not necessary due to how permutations were constructed.

-- Ensures each row is used only once, but that all possible orders are produced
allBoards :: Natural -> [Board]
allBoards = permutations . rowsOfLengthN

-- Read this function as "given a default empty row of length n, return all rows of length n with a single True"
possibleRows :: Natural -> [Bool] -> [[Bool]]
possibleRows n emptyRow =
    map (\idx -> fromMaybe [] $ set emptyRow idx True) [0..n -1]
    ...
```
That's not much of a change, but it has enormous ramifications on our solution.
In the initial solution all possible rows were generated in terms of their points, producing an `NxN` list of points.
The permutations were generated on the consideration of each point, i.e. take a point from the first row, then match it with all possible points in the second row, etc...
By comparison, this improved solution takes only the possible positions of a queen within an _arbitrary_ row rather than a specific one.
That seems like a small distinction, but by raising the abstraction level from points on the board to rows on the board the generation function guarantees all values produces are a solution to n-rooks.

The profile below illustrates this dramatic workload reduction this provides:

```
COST CENTRE                            MODULE         entries    %time %alloc
  main                                   Main               0    99.8  100.0
   nQueens1                              NQueens            1    99.8  100.0
    isValidBoard1                        NQueens        40320    97.8   98.1

```
This change cut the 8x8 board computation time from 107 seconds down to 0.14 seconds, 1000x faster is pretty good, but perhaps we can do even better?
In the next and final section I'll explain how moving from the "generate permutations & filter" approach towards a more sophisticated algorithm will let us get another order of magnitude speedup.

### Hello Recursion
The 8x8 solution has been pared from ~17 million steps to ~40 thousand, but there's something deeply unsatisfying about simply generating all of the permutations then filtering them out.
It means that in many cases, there may be a bad placement on the second row that's replicated across a thousand permutations, all failing validation due to the same queen placement.
This should make you wonder if there's a way to preemptively prune the invalid permutations from the final list at the moment they're introduced rather than at the end.
Which in turn tells you that if the filter conditions are pushed down into the generation itself, we should be able to reduce the search space at earliest possible moment.

The solution I ended up implementing is a row-by-row exploration of possible board layouts.
As each row is visited, the computation performs a depth-first search from all valid queen placements through the rest of the board.
At each placement all invalid locations are removed from the board so successive rows have a constrained set of squares to choose from.
This is much more complicated than the naive brute-force solution but truth be told, most of the complexity lies in the validation and book keeping not the algorithm itself.

Without futher ado, let's look at some code:

```haskell
computeValid4 ::
    Natural
    -> [SparseMatrix]
computeValid4 n =
    evalState (step (Depth $ n -1)) allPoints
    where
        allPoints = S.fromList [(X x, Y y) | x <- [0..n-1], y <- [0..n-1]]

        step :: Depth -> State (S.HashSet (X,Y)) [SparseMatrix]
        -- The base case, when there are no more branches to take. At this point,
        -- if there are any points remaining in the "available point" set, then these are all
        -- valid and should be added to the board
        step (Depth 0) = do
            remainingPoints <- S.toList <$> PR.get
            let toMatrix x = SparseMatrix {
                 numRows = n
                ,numCols = n
                ,values = S.fromList [x]
                }
            pure $ toMatrix <$> remainingPoints

        -- The inductive case. Compute each valid point on the row, then explore down the
        -- tree of possibilities for that point. Each time the algo explores deeper down the tree,
        -- it marks off all points invalidated by the chosen point
        step (Depth d) = do
            availablePoints <- PR.get
            let possibleRowPoints = sparseRowPerms n d
                validRowPoints = filter (`S.member` availablePoints) possibleRowPoints
            results <- traverse explore validRowPoints
            pure $ concat results
            where
                -- For a valid point:
                --  1) filter out the points invalidated by this point
                --  2) update the state to reflect that
                --  3) recursively compute the next setps based on the invalidated points
                --  4) reset the state back to what it started at
                --  5) Add the valid point to the results of the recursive exploration
                explore :: (X,Y) -> State (S.HashSet (X,Y)) [SparseMatrix]
                explore point = do
                    availablePoints <- PR.get
                    let filteredPoints = invalidatePoints point availablePoints
                    if null filteredPoints
                    then pure []
                    else  do
                        PR.put filteredPoints
                        results <- step (Depth $ d-1)
                        PR.put availablePoints -- This is the reset
                        let addToMatrix m@(SparseMatrix {values}) = m {values = S.insert point values}
                        pure $ addToMatrix <$> results
                    where
                        invalidatePoints :: (X, Y) -> S.HashSet (X,Y) -> S.HashSet (X,Y)
                        invalidatePoints (x, y) = S.filter (\(x', y') -> x' /= x && y' /= y && notOnDiagonal (x', y'))
                        ...
```
Yikes, that is a lot of code. Our lovely 10 line solution has become a dense 35 line monster!

The heart of this specific implementation is in the recursive search of `validRowPoints` within `step`.
That is the point where it locks in a specific set of rows & searches the remaining rows for any valid placements.

At this point, I hope you're asking yourself whether all of this complexity is worth it.
The best naive solution could solve this by checking 40k boards, what does the recursive solution get us?
Let's turn to the profiler for some hard evidence:

```
COST CENTRE                            MODULE      entries    %time %alloc
  main                                 Main              0    86.4   98.8
   nQueens4                            NQueens           0    86.4   98.8
    computeValid4                      NQueens           1    86.4   98.8
     computeValid4.step                NQueens        1641    86.4   98.4
      computeValid4.step.explore       NQueens        1964    59.1   69.8
      ...
```

The nice thing about this algorithm is that its guaranteed to provide a solution for any size of N.
The bad news is that it still grows with O(n!) complexity, albeit with a small constant factor applied.
So, while we're down to only 1641 search steps, this still chokes on large values of N.
Oh, and for the record, the recursive implementation above completes in less than 0.01s, for another 10x improvement over our best-case naive solution.
