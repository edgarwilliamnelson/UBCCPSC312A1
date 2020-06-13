Term project for CPSC 312 at the University of British Columbia.

Early in our exposure to functional programming the class was tasked to take an existing piece of Haskell software and augment it in some form to add additional functionality. 

The assignment focused on understanding a project in depth written in an unfamiliar language, and then introducing non-trivial changes that created new functionality. 

I took the implementation of a soduku solver from the blog post at https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/ and converted it to solving soduko X variant games.

The complexity of the program was far greater than the current level of the class, and diving into the program to see where alterations could be made was initially rather daunting. 

The key to the initial implementation was the function pruneGrid. 
The sudoku board's state at any step of the algorithm is represented as a two dimensional grid of cells. A cell may either be a fixed integer value, or unfixed and contain a list of possible integer value. The list of possible values is the set of all potential values for that cell that would not violate the rules of sudoku when compared to the fixed values on the current board. 

For the search algorithm to narrow down a solution, pruneGrid takes a sudoku grid and for each unfixed cell in the grid it removes all possible values from that cell that are equal to the value of a fixed cell in that unfixed cell’s row, as they would violate the rules of sudoku.

The same operation is performed on the columns of the grid by transposing the grid, making the columns the rows, and passing that grid to pruneGrid. This is done as pruneGrid only makes comparisons between cells in the same row.

To perform the last constraint for regular sudoku, that the 3x3 subgrids must contain all distinct values, the function subGridsToRows takes a sudoku grid and returns a new grid where each of the subgrids is its own row.  This is then pruned by pruneGrid. The resulting grid is then fed back into subGridsToRows that is conveniently its own back-transform. 

As pruneGrid was addressing the inital three constraints of regular sudoku, it was clearly the place to begin insertions that would addition the additional diagonal constraint for sudoku X.

As Haskell is a functional programming language the largest hurdle I encountered was the inability to consider the cells in the diagonals independently. The entire grid needed to maintained during the process of applying the diagonal constraint.

To facilitate this the cells from one diagonal were copied from the grid and placed in their own rows, these rows were then appended to the top of the top of the grid and this 10x9 Grid was then pruned. The now pruned diagonal cells were then reinserted into their original diagonal positions in the grid adding the needed constraint.
