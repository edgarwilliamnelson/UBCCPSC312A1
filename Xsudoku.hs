module Main where

import Control.Applicative ((<|>))
import qualified Control.Monad
import qualified Data.Char
import qualified Data.Function
import qualified Data.List.Split
import qualified Data.List

data Cell = Fixed Int | Possible [Int] deriving (Show, Eq)
type Row  = [Cell]
type Grid = [Row]

-- Generates a Grid from the given input string.
readGrid :: String -> Maybe Grid
readGrid s
  | length s == 81 = traverse (traverse readCell) . Data.List.Split.chunksOf 9 $ s
  | otherwise      = Nothing
  where
    readCell '.' = Just $ Possible [1..9]
    readCell c
      | Data.Char.isDigit c && c > '0' = Just . Fixed . Data.Char.digitToInt $ c
      | otherwise = Nothing

-- Outputs the grid state as a sudoku board.
showGrid :: Grid -> String
showGrid = unlines . map (unwords . map showCell)
  where
    showCell (Fixed x) = show x
    showCell _ = "."

-- Outputs the grid state with the current possible values for each cell displayed.
showGridWithPossibilities :: Grid -> String
showGridWithPossibilities = unlines . map (unwords . map showCell)
  where
    showCell (Fixed x)     = show x ++ "          "
    showCell (Possible xs) =
      (++ "]")
      . Data.List.foldl' (\acc x -> acc ++ if x `elem` xs then show x else " ") "["
      $ [1..9]

-- Prunes a list of cells by removing fixed values from the possible values of each
-- unfixed cell.
pruneCells :: [Cell] -> Maybe [Cell]
pruneCells cells = traverse pruneCell cells
  where
    fixeds = [x | Fixed x <- cells]

    pruneCell (Possible xs) = case xs Data.List.\\ fixeds of
      []  -> Nothing
      [y] -> Just $ Fixed y
      ys  -> Just $ Possible ys
    pruneCell x = Just x


--Constructs a new list from every nth element of a given list.
every n xs = case drop (n-1) xs of
              (y:ys) -> y : every n ys
              [] -> []

--Constructs a list by removing every nth element
remove_every_nth :: Int -> [a] -> [a]
remove_every_nth n = foldr step [] . zip [1..]
    where step (i,x) acc = if (i `mod` n) == 0 then acc else x:acc


--returns a new list formed from the contents of the old list grouped into groups of n.
group :: Int -> [a] -> [[a]]
group _ [] = []
group n l
  | n > 0 = (take n l) : (group n (drop n l))
  | otherwise = error "Negative n"



--inserts an element into a list at position n.
insertAt :: a -> Int -> [a] -> [a]
insertAt newElement _ [] = [newElement]
insertAt newElement i (a:as)
  | i <= 0 = newElement:a:as
  | otherwise = a : insertAt newElement (i - 1) as
  
  
--inserts elements into the right diagonal positions of a 9X9 grid.
insert1 :: [a] -> [a] -> Int -> Int -> [a]
insert1 (x:xs) [] _ _ = (x:xs)
insert1 [] (a:as) _ _ = (a:as)
insert1 (x:xs) (a:as) i n
  | n == 1 = (a:as) ++ (x:xs)
  | i == 1 = insert1 xs (a:x:as) 11 (n - 1)
  | otherwise = a : insert1 (x:xs) as (i - 1) n  

--inserts elements into the left diagonal positions of a 9X9 grid.
insert2 :: [a] -> [a] -> Int -> Int -> [a]
insert2 (x:xs) [] _ _ = (x:xs)
insert2 [] (a:as) _ _ = (a:as)
insert2 (x:xs) (a:as) i n
  | n == 1 && i == 1 = a : (insert2 xs (x:as) 0 0) 
  | i == 1 = insert2 xs (a:x:as) 9 (n - 1)
  | otherwise = a : insert2 (x:xs) as (i - 1) n  

--generates a new list of cells composed of the elements on the right diagonal of a 9x9 grid.
--attaches this list to the top of the input grid and returns that, essentially a 9x10 grid to be pruned with the 
--top row being the diagonal elements.
getDiagonal1 :: Grid -> Grid
getDiagonal1 lst = 
  let cut = ((concat lst)!!0 : (every 10 (drop 1(concat lst))))
    in (cut : lst)

--generates a new list of cells composed of the elements on the left diagonal of a 9x9 grid
--attaches this list to the top of the input grid and returns that, essentially a 9x10 grid to be pruned with the 
--top row being the diagonal elements.
getDiagonal2 :: Grid -> Grid
getDiagonal2 lst = 
   let cut = (take 9 ( (drop 8 (concat lst))!!0 : (every 8 (drop 9 (concat lst)))))
    in (cut : lst)


--takes a 9x10 grid, removes the top row (this will be the diagonal elements) and replaces the current right diagonal elements 
--from the removed row.
insertBack1 :: Grid -> Grid
insertBack1 cells = 
 let diagonals = take 1 cells
  in let newGrid = drop 1 cells
   in let rightDiagonal = (remove_every_nth 10 (drop 1 (concat newGrid))) 
    in let final = insert1 (drop 1 (head diagonals)) ((head (head diagonals)) : rightDiagonal) 10 9
      in   group 9 final

--takes a 9x10 grid, removes the top row (the diagonal elements) and replaces the current left diagonal elements of the 9x9 grid with the elements
--from the removed row.
insertBack2 :: Grid -> Grid
insertBack2 cells =
 let diagonals = take 1 cells
  in let newGrid = drop 1 cells
   in let workGrid = concat newGrid
   in let leftDiagonal = (((take 8 workGrid) ++ (remove_every_nth 8 (drop 9 workGrid))) ++ (drop 80 workGrid))
    in let final = insert2 (diagonals!!0) leftDiagonal 8 9 
      in   group 9 final



-- As the prune function only works on grids, this function converts each of the 3x3 subgrids into individual rows to be pruned.
subGridsToRows :: Grid -> Grid
subGridsToRows =
  concatMap (\rows -> let [r1, r2, r3] = map (Data.List.Split.chunksOf 3) rows
                      in zipWith3 (\a b c -> a ++ b ++ c) r1 r2 r3)
  . Data.List.Split.chunksOf 3

-- Helper: prunes a Grid by removing Fixed values from Possible values where neccessary
pruneGrid' :: Grid -> Maybe Grid
pruneGrid' grid =
  traverse pruneCells grid
  >>= fmap Data.List.transpose . traverse pruneCells . Data.List.transpose
  >>= fmap subGridsToRows . traverse pruneCells . subGridsToRows
  >>= fmap insertBack1. traverse pruneCells . getDiagonal1  
  >>= fmap insertBack2. traverse pruneCells . getDiagonal2   
                                                            


-- Prunes a Grid by removing Fixed values from Possible values where necessary
pruneGrid :: Grid -> Maybe Grid
pruneGrid = fixM pruneGrid'
  where
    fixM f x = f x >>= \x' -> if x' == x then return x else fixM f x'

-- Checks if grid is solved by looking to see if any unsolved cells exist in the grid.
isGridFilled :: Grid -> Bool
isGridFilled grid = null [ () | Possible _ <- concat grid ]



-- Checks if a grid is valid by looking for any duplicate fixed cells and any empty unsolved cells.
isGridInvalid :: Grid -> Bool
isGridInvalid grid =
  any isInvalidRow grid
  || any isInvalidRow (Data.List.transpose grid)
  || any isInvalidRow (subGridsToRows grid)
  where
    isInvalidRow row =
      let fixeds         = [x | Fixed x <- row]
          emptyPossibles = [x | Possible x <- row, null x]
      in hasDups fixeds || not (null emptyPossibles)

    hasDups l = hasDups' l []

    hasDups' [] _ = False
    hasDups' (y:ys) xs
      | y `elem` xs = True
      | otherwise   = hasDups' ys (y:xs)

--When grid is in a settled state, set the value of an unsolved cell and see if this can lead to a solution.
nextGrids :: Grid -> (Grid, Grid)
nextGrids grid =
  let (i, first@(Fixed _), rest) =
        fixCell
        . Data.List.minimumBy (compare `Data.Function.on` (possibilityCount . snd))
        . filter (isPossible . snd)
        . zip [0..]
        . concat
        $ grid
  in (replace2D i first grid, replace2D i rest grid)
  where
    isPossible (Possible _) = True
    isPossible _            = False

    possibilityCount (Possible xs) = length xs
    possibilityCount (Fixed _)     = 1

    fixCell (i, Possible [x, y]) = (i, Fixed x, Fixed y)
    fixCell (i, Possible (x:xs)) = (i, Fixed x, Possible xs)
    fixCell _                    = error "Impossible case"

    replace2D :: Int -> a -> [[a]] -> [[a]]
    replace2D i v = let (x, y) = (i `quot` 9, i `mod` 9) in replace x (replace y (const v))
    replace p f xs = [if i == p then f x else x | (x, i) <- zip xs [0..]]


-- Returns the solution to a given soduku board if it exists.
solve :: Grid -> Maybe Grid
solve grid = pruneGrid grid >>= solve'
  where
    solve' g
      | isGridInvalid g = Nothing
      | isGridFilled g  = Just g
      | otherwise       =
          let (grid1, grid2) = nextGrids g
          in solve grid1 <|> solve grid2

  
-- Main wrapper around solve to call it from the command line
main :: IO ()
main = do
  inputs <- lines <$> getContents
  Control.Monad.forM_ inputs $ \input ->
    case readGrid input of
      Nothing   -> putStrLn "Invalid input"
      Just grid -> case solve grid of
        Nothing    -> putStrLn "No solution found"
        Just grid' -> putStrLn $ showGrid grid'