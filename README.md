Term project for CPSC 312 at the University of British Columbia.

Early in our exposure to functional programming the class was tasked to take an existing piece of Haskell software and augment it in some form to add additional functionality. 

The assignment focused on understanding a project written in an unfamiliar language in depth, and then introducing non-trivial changes that created new functionality. 

I took the implementation of a soduku solver from the blog post at https://abhinavsarkar.net/posts/fast-sudoku-solver-in-haskell-1/ and converted it to solving soduko X variant games.

The complexity of the program was far greater than the current level of the class, and diving into the program to see where alterations could be made was initially rather daunting. 

The key to the initial implementation's backtracking algorithm was the function pruneGrid. 
The sudoku board's state at any step of the algorithm is represented as a two dimensional grid of cells. A cell may either be a fixed integer value, or unfixed and contain a list of possible integer values. For a unfixed cell the list of possible values is the set of all values that cell could hold that would not violate the rules of sudoku when compared to the fixed values on the current board. 

For a sudoku solution to be valid all values in each row, column, and 3x3 subgrid must be distinct. For the search algorithm to narrow down a solution, pruneGrid enforces these constraints in the following three operations:

1) The current grid is passed to pruneGrid, for each unfixed cell in the grid it removes all values from that cell's set of possibilities that are equal to a fixed cell in the current unfixed cell's row.  

2) The same operation is performed on the columns by transposing the grid, thus making the columns into the rows, and passing that grid to pruneGrid. This is done as pruneGrid only makes comparisons between cells in the same row. The grid is then transposed again returning the rows back to their original positions. This can be seen on line 153 of Xsudoku.hs.

3) To perform the last constraint for regular sudoku, that each of the four 3x3 subgrids must contain all distinct values, the function subGridsToRows takes a sudoku grid and returns a new grid where each of the subgrids is its own row.  This is then pruned by pruneGrid. The resulting grid is then fed back into subGridsToRows that is conveniently its own back-transform. 

As pruneGrid was addressing the inital three constraints of regular sudoku, it was clearly the place to begin insertions that would addition the additional diagonal constraint for sudoku X.

Since Haskell is a  purely functional programming language the largest hurdle I encountered was the inability to consider the cells in the diagonals independently. The entire grid needed to maintained during the process of applying the diagonal constraint.

To facilitate this the cells from the diagonals were copied from the grid and placed in their own rows, these rows were then appended to the top of the grid and this 10x9 Grid was then passed to pruneCells. The diagonal cells would then have the necessary comparisons made and potential values removed. They would then be reinserted back into their original positions in the grid (overwriting their unpruned originals). Thus adding the additional constraint of sudoku X.