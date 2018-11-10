-- |
-- Module      : Test.LeanCheck.Function.Show.EightLines
-- Copyright   : (c) 2015-2018 Rudy Matela
-- License     : 3-Clause BSD  (see the file LICENSE)
-- Maintainer  : Rudy Matela <rudy@matela.com.br>
--
-- This module is part of LeanCheck,
-- a simple enumerative property-based testing library.
--
-- This module exports an orphan 'Show' instance for functions.
-- It shows functions as up to 8 case distinctions, one per line.
--
-- Please see "Test.LeanCheck.Function.Show.FourCases" for an alternative that
-- shows functions as up to 4 case distinctions in a single line.
--
-- The 'Show' '->' instance only works for functions of which ultimate return
-- types are instances of the 'ShowFunction' typeclass.  Please see
-- "Test.LeanCheck.Function.ShowFunction" for how to define these instances for
-- your user-defined algebraic datatypes.
--
-- Warning: this is only intended to be used in testing modules.  Avoid
-- importing this on modules that are used as libraries.
module Test.LeanCheck.Function.Show.EightLines () where

import Test.LeanCheck.Function.ShowFunction

-- | A multi-line show instance for functions.
--
-- This is intended to 'Show' functions generated by the 'Listable' instance
-- for functions defined in "Test.LeanCheck.Function.Listable": functions that
-- have finite exceptions to a constant function.  It does work on other types
-- of functions, albeit using @"..."@.
--
-- > > print (&&)
-- > \x y -> case (x,y) of
-- >         (True,True) -> True
-- >         _ -> False
--
-- > > print (==>)
-- > \x y -> case (x,y) of
-- >         (True,False) -> False
-- >         _ -> True
--
-- > > print (==2)
-- > \x -> case x of
-- >       2 -> True
-- >       _ -> False
--
-- > > print (\x -> abs x < 2)
-- > \x -> case x of
-- >       0 -> True
-- >       1 -> True
-- >       -1 -> True
-- >       _ -> False
--
-- When the function cannot be defined by finite exceptions to a constant
-- function using 8 case-patterns, the rest of the function is represented by
-- @"..."@.
--
-- > > print (+)
-- > \x y -> case (x,y) of
-- >         (0,0) -> 0
-- >         (0,1) -> 1
-- >         (1,0) -> 1
-- >         (0,-1) -> -1
-- >         (1,1) -> 2
-- >         (-1,0) -> -1
-- >         (0,2) -> 2
-- >         (1,-1) -> 0
-- >         ...
instance (Show a, Listable a, ShowFunction b) => Show (a->b) where
  showsPrec _ = (++) . showFunction 8
