-- |
-- Module      : Test.LeanCheck.Function.Show
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
-- /Warning: this is only intended to be used in testing modules./
-- /Avoid importing this on modules that are used as libraries./
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
--
-- The exported orphan 'Show' '->' instance is actually defined in
-- "Test.LeanCheck.Function.Show.EightLines".  An alternative is provided in
-- "Test.LeanCheck.Function.Show.FourCases".
--
-- The exported 'Show' instance only works for functions whose ultimate return
-- types are instances of 'Test.LeanCheck.Function.ShowFunction.ShowFunction'.
-- For user-defined algebraic datatypes that are instances of 'Show', their
-- ShowFunction instance can be defined by using
-- 'Test.LeanCheck.Function.ShowFunction.bindtiersShow':
--
-- > import Test.LeanCheck.Function.ShowFunction
-- >
-- > instance ShowFunction Ty where
-- >   bindtiers = bindtiersShow
module Test.LeanCheck.Function.Show () where

import Test.LeanCheck.Function.Show.EightLines ()
