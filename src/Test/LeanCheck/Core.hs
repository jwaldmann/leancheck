-- |
-- Module      : Test.LeanCheck.Core
-- Copyright   : (c) 2015-2018 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- LeanCheck is a simple enumerative property-based testing library.
--
-- This is the core module of the library, with the most basic definitions.  If
-- you are looking just to use the library, import and see "Test.LeanCheck".
--
-- If you want to understand how the code works, this is the place to start
-- reading.
--
--
-- Other important modules:
--
-- * "Test.LeanCheck.Basic" exports:
--     "Test.LeanCheck.Core",
--     additional 'tiers' constructors
--       ('Test.LeanCheck.Basic.cons6' ...
--        'Test.LeanCheck.Basic.cons12') and
--     'Listable' tuple instances.
--
-- * "Test.LeanCheck.Tiers" exports:
--     functions for advanced Listable definitions.
--
-- * "Test.LeanCheck" exports:
--      "Test.LeanCheck.Basic",
--      most of "Test.LeanCheck.Tiers" and
--      'Test.LeanCheck.Derive.deriveListable'.
module Test.LeanCheck.Core
  (
  -- * Checking and testing
    holds
  , fails
  , exists
  , counterExample
  , counterExamples
  , witness
  , witnesses
  , Testable(..)

  , results

  -- * Listing test values
  , Listable(..)

  -- ** Constructing lists of tiers
  , cons0
  , cons1
  , cons2
  , cons3
  , cons4
  , cons5

  , delay
  , reset
  , suchThat

  -- ** Combining lists of tiers
  , (\/), (\\//)
  , (><)
  , productWith

  -- ** Manipulating lists of tiers
  , mapT
  , filterT
  , concatT
  , concatMapT
  , toTiers

  -- ** Boolean (property) operators
  , (==>)

  -- ** Misc utilities
  , (+|)
  , listIntegral
  , tiersFractional
  , tiersFloating
  )
where

import Data.Maybe (listToMaybe)


-- | A type is 'Listable' when there exists a function that
--   is able to list (ideally all of) its values.
--
-- Ideally, instances should be defined by a 'tiers' function that
-- returns a (potentially infinite) list of finite sub-lists (tiers):
--   the first sub-list contains elements of size 0,
--   the second sub-list contains elements of size 1
--   and so on.
-- Size here is defined by the implementor of the type-class instance.
--
-- For algebraic data types, the general form for 'tiers' is
--
-- > tiers = cons<N> ConstructorA
-- >      \/ cons<N> ConstructorB
-- >      \/ ...
-- >      \/ cons<N> ConstructorZ
--
-- where @N@ is the number of arguments of each constructor @A...Z@.
--
-- Here is a datatype with 4 constructors and its listable instance:
--
-- > data MyType  =  MyConsA
-- >              |  MyConsB Int
-- >              |  MyConsC Int Char
-- >              |  MyConsD String
-- >
-- > instance Listable MyType where
-- >   tiers =  cons0 MyConsA
-- >         \/ cons1 MyConsB
-- >         \/ cons2 MyConsC
-- >         \/ cons1 MyConsD
--
-- The instance for Hutton's Razor is given by:
--
-- > data Expr  =  Val Int
-- >            |  Add Expr Expr
-- >
-- > instance Listable Expr where
-- >   tiers  =  cons1 Val
-- >          \/ cons2 Add
--
-- Instances can be alternatively defined by 'list'.
-- In this case, each sub-list in 'tiers' is a singleton list
-- (each succeeding element of 'list' has +1 size).
--
-- The function 'Test.LeanCheck.Derive.deriveListable' from "Test.LeanCheck.Derive"
-- can automatically derive instances of this typeclass.
--
-- A 'Listable' instance for functions is also available but is not exported by
-- default.  Import "Test.LeanCheck.Function" if you need to test higher-order
-- properties.
class Listable a where
  tiers :: [[a]]
  list :: [a]
  tiers = toTiers list
  list = concat tiers
  {-# MINIMAL list | tiers #-}

-- | Takes a list of values @xs@ and transform it into tiers on which each
--   tier is occupied by a single element from @xs@.
--
-- > > toTiers [x, y, z, ...]
-- > [ [x], [y], [z], ...]
--
-- To convert back to a list, just 'concat'.
toTiers :: [a] -> [[a]]
toTiers = map (:[])

-- | > list :: [()]  =  [()]
--   > tiers :: [[()]]  =  [[()]]
instance Listable () where
  list = [()]

-- | Tiers of 'Integral' values.
--   Can be used as a default implementation of 'list' for 'Integral' types.
--
-- For types with negative values, like 'Int',
-- the list starts with 0 then intercalates between positives and negatives.
--
-- > listIntegral  =  [0, 1, -1, 2, -2, 3, -3, 4, -4, ...]
--
-- For types without negative values, like 'Word',
-- the list starts with 0 followed by positives of increasing magnitude.
--
-- > listIntegral  =  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ...]
--
-- This function will not work for types that throw errors when the result of
-- an arithmetic operation is negative such as 'GHC.Natural'.  For these, use
-- @[0..]@ as the 'list' implementation.
listIntegral :: (Ord a, Num a) => [a]
listIntegral = 0 : positives +| negatives
  where
  positives = takeWhile (>0) $ iterate (+1) 1  -- stop generating on overflow
  negatives = takeWhile (<0) $ iterate (subtract 1) (-1)

-- | > tiers :: [[Int]] = [[0], [1], [-1], [2], [-2], [3], [-3], ...]
--   > list :: [Int] = [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, ...]
instance Listable Int where
  list = listIntegral

-- | > list :: [Int] = [0, 1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, ...]
instance Listable Integer where
  list = listIntegral

-- | > list :: [Char] = ['a', ' ', 'b', 'A', 'c', '\', 'n', 'd', ...]
instance Listable Char where
  list = ['a'..'z']
      +| [' ','\n']
      +| ['A'..'Z']
      +| ['0'..'9']
      +| ['!'..'/']
      +| ['\t']
      +| [':'..'@']
      +| ['['..'`']
      +| ['{'..'~']

-- | > tiers :: [[Bool]] = [[False,True]]
--   > list :: [[Bool]] = [False,True]
instance Listable Bool where
  tiers = cons0 False \/ cons0 True

-- | > tiers :: [[Maybe Int]] = [[Nothing], [Just 0], [Just 1], ...]
--   > tiers :: [[Maybe Bool]] = [[Nothing], [Just False, Just True]]
instance Listable a => Listable (Maybe a) where
  tiers = cons0 Nothing \/ cons1 Just

-- | > tiers :: [[Either Bool Bool]] =
--   >   [[Left False, Right False, Left True, Right True]]
--   > tiers :: [[Either Int Int]] = [ [Left 0, Right 0]
--   >                               , [Left 1, Right 1]
--   >                               , [Left (-1), Right (-1)]
--   >                               , [Left 2, Right 2]
--   >                               , ... ]
instance (Listable a, Listable b) => Listable (Either a b) where
  tiers = reset (cons1 Left)
     \\// reset (cons1 Right)

-- | > tiers :: [[(Int,Int)]] =
--   > [ [(0,0)]
--   > , [(0,1),(1,0)]
--   > , [(0,-1),(1,1),(-1,0)]
--   > , ...]
--   > list :: [(Int,Int)] = [ (0,0), (0,1), (1,0), (0,-1), (1,1), ...]
instance (Listable a, Listable b) => Listable (a,b) where
  tiers = tiers >< tiers

-- | > list :: [(Int,Int,Int)] = [ (0,0,0), (0,0,1), (0,1,0), ...]
instance (Listable a, Listable b, Listable c) => Listable (a,b,c) where
  tiers = productWith (\x (y,z) -> (x,y,z)) tiers tiers

instance (Listable a, Listable b, Listable c, Listable d) =>
         Listable (a,b,c,d) where
  tiers = productWith (\(x,y) (z,w) -> (x,y,z,w)) tiers tiers

instance (Listable a, Listable b, Listable c, Listable d, Listable e) =>
         Listable (a,b,c,d,e) where
  tiers = productWith (\(x,y) (z,w,v) -> (x,y,z,w,v)) tiers tiers

-- | > tiers :: [[ [Int] ]] = [ [ [] ]
--   >                        , [ [0] ]
--   >                        , [ [0,0], [1] ]
--   >                        , [ [0,0,0], [0,1], [1,0], [-1] ]
--   >                        , ... ]
--   > list :: [ [Int] ] = [ [], [0], [0,0], [1], [0,0,0], ... ]
instance (Listable a) => Listable [a] where
  tiers = cons0 []
       \/ cons2 (:)

-- | Tiers of 'Fractional' values.
--   This can be used as the implementation of 'tiers' for 'Fractional' types.
--
-- > tiersFractional :: [[Rational]]  =
-- >   [ [  0  % 1]
-- >   , [  1  % 1]
-- >   , [(-1) % 1]
-- >   , [  1  % 2,   2  % 1]
-- >   , [(-1) % 2, (-2) % 1]
-- >   , [  1  % 3,   3  % 1]
-- >   , [(-1) % 3, (-3) % 1]
-- >   , [  1  % 4,   2  % 3,   3  % 2,   4  % 1]
-- >   , [(-1) % 4, (-2) % 3, (-3) % 2, (-4) % 1]
-- >   , [  1  % 5,   5  % 1]
-- >   , [(-1) % 5, (-5) % 1]
-- >   , [  1  % 6,   2 % 5,    3  % 4,   4  % 3,   5  % 2,   6  % 1]
-- >   , [(-1) % 6, (-2) % 5, (-3) % 4, (-4) % 3, (-5) % 2, (-6) % 1]
-- >   , ...
-- >   ]
tiersFractional :: Fractional a => [[a]]
tiersFractional = mapT (\(x,y) -> fromInteger x / fromInteger y) . reset
                $ tiers `suchThat` \(n,d) -> d > 0 && n `gcd` d == 1

-- | Tiers of 'Floating' values.
--   This can be used as the implementation of 'tiers' for 'Floating' types.
--
--   This function is equivalent to 'tiersFractional'
--   with positive and negative infinities included: 1/0 and -1/0.
--
-- > tiersFloating :: [[Float]] =
-- >   [ [0.0]
-- >   , [1.0]
-- >   , [-1.0, Infinity]
-- >   , [ 0.5,  2.0, -Infinity]
-- >   , [-0.5, -2.0]
-- >   , [ 0.33333334,  3.0]
-- >   , [-0.33333334, -3.0]
-- >   , [ 0.25,  0.6666667,  1.5,  4.0]
-- >   , [-0.25, -0.6666667, -1.5, -4.0]
-- >   , [ 0.2,  5.0]
-- >   , [-0.2, -5.0]
-- >   , [ 0.16666667,  0.4,  0.75,  1.3333334,  2.5,  6.0]
-- >   , [-0.16666667, -0.4, -0.75, -1.3333334, -2.5, -6.0]
-- >   , ...
-- >   ]
--
--   @NaN@ and @-0@ are excluded from this enumeration.
tiersFloating :: Fractional a => [[a]]
tiersFloating = tiersFractional \/ [ [], [], [1/0], [-1/0] {- , [-0], [0/0] -} ]

-- | @NaN@ and @-0@ are not included in the list of 'Float's.
--
-- > list :: [Float] =
-- >   [ 0.0
-- >   , 1.0, -1.0, Infinity
-- >   , 0.5, 2.0, -Infinity, -0.5, -2.0
-- >   , 0.33333334, 3.0, -0.33333334, -3.0
-- >   , 0.25, 0.6666667, 1.5, 4.0, -0.25, -0.6666667, -1.5, -4.0
-- >   , ...
-- >   ]
instance Listable Float where
  tiers = tiersFloating

-- | @NaN@ and @-0@ are not included in the list of 'Double's.
--
-- > list :: [Double]  =  [0.0, 1.0, -1.0, Infinity, 0.5, 2.0, ...]
instance Listable Double where
  tiers = tiersFloating

-- | > list :: [Ordering]  = [LT, EQ, GT]
instance Listable Ordering where
  tiers = cons0 LT
       \/ cons0 EQ
       \/ cons0 GT

-- | 'map' over tiers
--
-- > mapT f [[x], [y,z], [w,...], ...]  =  [[f x], [f y, f z], [f w, ...], ...]
--
-- > mapT f [xs, ys, zs, ...]  =  [map f xs, map f ys, map f zs]
mapT :: (a -> b) -> [[a]] -> [[b]]
mapT = map . map

-- | 'filter' tiers
--
-- > filterT p [xs, yz, zs, ...]  =  [filter p xs, filter p ys, filter p zs]
--
-- > filterT odd tiers  =  [[], [1], [-1], [], [], [3], [-3], [], [], [5], ...]
filterT :: (a -> Bool) -> [[a]] -> [[a]]
filterT f = map (filter f)

-- | 'concat' tiers of tiers
concatT :: [[ [[a]] ]] -> [[a]]
concatT = foldr (\+:/) [] . map (foldr (\/) [])
  where xss \+:/ yss = xss \/ ([]:yss)

-- | 'concatMap' over tiers
concatMapT :: (a -> [[b]]) -> [[a]] -> [[b]]
concatMapT f = concatT . mapT f


-- | Given a constructor with no arguments,
--   returns 'tiers' of all possible applications of this constructor.
--   Since in this case there is only one possible application (to no
--   arguments), only a single value, of size/weight 0, will be present in the
--   resulting list of tiers.
cons0 :: a -> [[a]]
cons0 x = [[x]]

-- | Given a constructor with one 'Listable' argument,
--   return 'tiers' of applications of this constructor.
--   By default, returned values will have size/weight of 1.
cons1 :: Listable a => (a -> b) -> [[b]]
cons1 f = delay $ mapT f tiers

-- | Given a constructor with two 'Listable' arguments,
--   return 'tiers' of applications of this constructor.
--   By default, returned values will have size/weight of 1.
cons2 :: (Listable a, Listable b) => (a -> b -> c) -> [[c]]
cons2 f = delay $ mapT (uncurry f) tiers

-- | Returns tiers of applications of a 3-argument constructor.
cons3 :: (Listable a, Listable b, Listable c) => (a -> b -> c -> d) -> [[d]]
cons3 f = delay $ mapT (uncurry3 f) tiers

-- | Returns tiers of applications of a 4-argument constructor.
cons4 :: (Listable a, Listable b, Listable c, Listable d)
      => (a -> b -> c -> d -> e) -> [[e]]
cons4 f = delay $ mapT (uncurry4 f) tiers

-- | Returns tiers of applications of a 5-argument constructor.
--
-- "Test.LeanCheck.Basic" defines
-- 'Test.LeanCheck.Basic.cons6' up to 'Test.LeanCheck.Basic.cons12'.
-- Those are exported by default from "Test.LeanCheck",
-- but are hidden from the Haddock documentation.
cons5 :: (Listable a, Listable b, Listable c, Listable d, Listable e)
      => (a -> b -> c -> d -> e -> f) -> [[f]]
cons5 f = delay $ mapT (uncurry5 f) tiers

-- | Delays the enumeration of 'tiers'.
-- Conceptually this function adds to the weight of a constructor.
--
-- > delay [xs, ys, zs, ... ]  =  [[], xs, ys, zs, ...]
--
-- > delay [[x,...], [y,...], ...]  =  [[], [x,...], [y,...], ...]
--
-- Typically used when defining 'Listable' instances:
--
-- > instance Listable <Type> where
-- >   tiers  =  ...
-- >          \/ delay (cons<N> <Constructor>)
-- >          \/ ...
delay :: [[a]] -> [[a]]
delay = ([]:)

-- | Resets any delays in a list-of 'tiers'.
-- Conceptually this function makes a constructor "weightless",
-- assuring the first tier is non-empty.
--
-- > reset [[], [], ..., xs, ys, zs, ...]  =  [xs, ys, zs, ...]
--
-- > reset [[], xs, ys, zs, ...]  =  [xs, ys, zs, ...]
--
-- > reset [[], [], ..., [x], [y], [z], ...]  =  [[x], [y], [z], ...]
--
-- Typically used when defining 'Listable' instances:
--
-- > instance Listable <Type> where
-- >   tiers  =  ...
-- >          \/ reset (cons<N> <Constructor>)
-- >          \/ ...
--
-- Be careful: do not apply @reset@ to recursive data structure
-- constructors.  In general this will make the list of size 0 infinite,
-- breaking the 'tiers' invariant (each tier must be finite).
reset :: [[a]] -> [[a]]
reset = dropWhile null

-- | Tiers of values that follow a property.
--
-- Typically used in the definition of 'Listable' tiers:
--
-- > instance Listable <Type> where
-- >   tiers  =  ...
-- >          \/ cons<N> `suchThat` <condition>
-- >          \/ ...
--
-- Examples:
--
-- > > tiers `suchThat` odd
-- > [[], [1], [-1], [], [], [3], [-3], [], [], [5], ...]
--
-- > > tiers `suchThat` even
-- > [[0], [], [], [2], [-2], [], [], [4], [-4], [], ...]
--
-- This function is just a 'flip'ped version of `filterT`.
suchThat :: [[a]] -> (a->Bool) -> [[a]]
suchThat = flip filterT

-- | Lazily interleaves two lists, switching between elements of the two.
--   Union/sum of the elements in the lists.
--
-- > [x,y,z,...] +| [a,b,c,...]  =  [x,a,y,b,z,c,...]
(+|) :: [a] -> [a] -> [a]
[]     +| ys = ys
(x:xs) +| ys = x:(ys +| xs)
infixr 5 +|

-- | Append tiers --- sum of two tiers enumerations.
--
-- > [xs,ys,zs,...] \/ [as,bs,cs,...]  =  [xs+|as, ys+|bs, zs+|cs, ...]
(\/) :: [[a]] -> [[a]] -> [[a]]
(\/) = (\\//)
infixr 7 \/

-- | Interleave tiers --- sum of two tiers enumerations.
--
-- > [xs,ys,zs,...] \/ [as,bs,cs,...]  =  [xs+|as, ys+|bs, zs+|cs, ...]
(\\//) :: [[a]] -> [[a]] -> [[a]]
xss \\// []  = xss
[]  \\// yss = yss
(xs:xss) \\// (ys:yss) = (xs +| ys) : xss \\// yss
infixr 7 \\//

-- | Take a tiered product of lists of tiers.
--
-- > [t0,t1,t2,...] >< [u0,u1,u2,...]  =
-- >   [ t0**u0
-- >   , t0**u1 ++ t1**u0
-- >   , t0**u2 ++ t1**u1 ++ t2**u0
-- >   , ...       ...       ...       ...
-- >   ]
-- >   where xs ** ys = [(x,y) | x <- xs, y <- ys]
--
-- Example:
--
-- > [[0],[1],[2],...] >< [[0],[1],[2],...]  =
-- >   [ [(0,0)]
-- >   , [(1,0),(0,1)]
-- >   , [(2,0),(1,1),(0,2)]
-- >   , [(3,0),(2,1),(1,2),(0,3)]
-- >   , ...
-- >   ]
(><) :: [[a]] -> [[b]] -> [[(a,b)]]
(><) = productWith (,)
infixr 8 ><

-- | Take a tiered product of lists of tiers.
--   'productWith' can be defined by '><', as:
--
-- > productWith f xss yss  =  map (uncurry f) $ xss >< yss
productWith :: (a->b->c) -> [[a]] -> [[b]] -> [[c]]
productWith f xss yss =
  map concat $ listProductWith ( \ xs ys -> concat $ listProductWith f xs ys ) xss yss

-- | anti-diagonal enumeration
-- > listProductWith f [x0,x1..] [y0,y1..] =
-- >   [[f x0 y0], [f x1 y0, f x0 y1], [f x2 y0, f x1 y1, f x0 y2], ..]
listProductWith :: (a -> b -> c) -> [a] -> [b] -> [[c]]
listProductWith f xs [] = []
listProductWith f [] ys = []
listProductWith f (x:xs) (y:ys) =
  [ f x y ] : zip_with_cons ( map (\x -> f x y) xs ) (listProductWith f (x:xs) ys)

zip_with_cons :: [a] -> [[a]] -> [[a]]
zip_with_cons xs [] = map (:[]) xs
zip_with_cons [] ys = ys
zip_with_cons (x:xs) (y:ys) = (x:y) : zip_with_cons xs ys



-- | 'Testable' values are functions
--   of 'Listable' arguments that return boolean values.
--
-- * @ Bool @
-- * @ Listable a => a -> Bool @
-- * @ (Listable a, Listable b) => a -> b -> Bool @
-- * @ (Listable a, Listable b, Listable c) => a -> b -> c -> Bool @
-- * @ (Listable a, Listable b, Listable c, ...) => a -> b -> c -> ... -> Bool @
--
-- For example:
--
-- * @ Int -> Bool @
-- * @ String -> [Int] -> Bool @
class Testable a where
  resultiers :: a -> [[([String],Bool)]]

instance Testable Bool where
  resultiers p = [[([],p)]]

instance (Testable b, Show a, Listable a) => Testable (a->b) where
  resultiers p = concatMapT resultiersFor tiers
    where resultiersFor x = mapFst (showsPrec 11 x "":) `mapT` resultiers (p x)
          mapFst f (x,y) = (f x, y)

-- | List all results of a 'Testable' property.
-- Each result is a pair of a list of strings and a boolean.
-- The list of strings is a printable representation of one possible choice of
-- argument values for the property.  Each boolean paired with such a list
-- indicates whether the property holds for this choice.  The outer list is
-- potentially infinite and lazily evaluated.
--
-- > > results (<)
-- > [ (["0","0"],    False)
-- > , (["0","1"],    True)
-- > , (["1","0"],    False)
-- > , (["0","(-1)"], False)
-- > , (["1","1"],    False)
-- > , (["(-1)","0"], True)
-- > , (["0","2"],    True)
-- > , (["1","(-1)"], False)
-- > , ...
-- > ]
--
-- > > take 10 $ results (\xs -> xs == nub (xs :: [Int]))
-- > [ (["[]"],      True)
-- > , (["[0]"],     True)
-- > , (["[0,0]"],   False)
-- > , (["[1]"],     True)
-- > , (["[0,0,0]"], False)
-- > , ...
-- > ]
results :: Testable a => a -> [([String],Bool)]
results = concat . resultiers

-- | Lists all counter-examples for a number of tests to a property,
--
-- > > counterExamples 12 $ \xs -> xs == nub (xs :: [Int])
-- > [["[0,0]"],["[0,0,0]"],["[0,0,0,0]"],["[0,0,1]"],["[0,1,0]"]]
counterExamples :: Testable a => Int -> a -> [[String]]
counterExamples n p = [as | (as,False) <- take n (results p)]

-- | Up to a number of tests to a property,
--   returns 'Just' the first counter-example
--   or 'Nothing' if there is none.
--
-- > > counterExample 100 $ \xs -> [] `union` xs == (xs::[Int])
-- > Just ["[0,0]"]
counterExample :: Testable a => Int -> a -> Maybe [String]
counterExample n = listToMaybe . counterExamples n

-- | Lists all witnesses up to a number of tests to a property.
--
-- > > witnesses 1000 (\x -> x > 1 && x < 77 && 77 `rem` x == 0)
-- > [["7"],["11"]]
witnesses :: Testable a => Int -> a -> [[String]]
witnesses n p = [as | (as,True) <- take n (results p)]

-- | Up to a number of tests to a property,
--   returns 'Just' the first witness
--   or 'Nothing' if there is none.
--
-- > > witness 1000 (\x -> x > 1 && x < 77 && 77 `rem` x == 0)
-- > Just ["7"]
witness :: Testable a => Int -> a -> Maybe [String]
witness n = listToMaybe . witnesses n

-- | Does a property __hold__ up to a number of test values?
--
-- > holds 1000 $ \xs -> length (sort xs) == length xs
holds :: Testable a => Int -> a -> Bool
holds n = and . take n . map snd . results

-- | Does a property __fail__ for a number of test values?
--
-- > fails 1000 $ \xs -> xs ++ ys == ys ++ xs
fails :: Testable a => Int -> a -> Bool
fails n = not . holds n

-- | There __exists__ an assignment of values that satisfies a property
--   up to a number of test values?
--
-- > exists 1000 $ \x -> x > 10
exists :: Testable a => Int -> a -> Bool
exists n = or . take n . map snd . results

uncurry3 :: (a->b->c->d) -> (a,b,c) -> d
uncurry3 f (x,y,z) = f x y z

uncurry4 :: (a->b->c->d->e) -> (a,b,c,d) -> e
uncurry4 f (x,y,z,w) = f x y z w

uncurry5 :: (a->b->c->d->e->f) -> (a,b,c,d,e) -> f
uncurry5 f (x,y,z,w,v) = f x y z w v

-- | Boolean implication operator.  Useful for defining conditional properties:
--
-- > prop_something x y = condition x y ==> something x y
--
-- Examples:
--
-- > > prop_addMonotonic x y  =  y > 0 ==> x + y > x
-- > > check prop_addMonotonic
-- > +++ OK, passed 200 tests.
(==>) :: Bool -> Bool -> Bool
False ==> _ = True
True  ==> p = p
infixr 0 ==>
