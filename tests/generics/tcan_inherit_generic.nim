##
## can_inherit_generic Nim Module
##
## Created by Eric Doughty-Papassideris on 2011-02-16.
## Copyright (c) 2011 FWA. All rights reserved.

type
  TGen[T] = object of TObject
    x, y: T

  TSpef[T] = object of TGen[T]


var s: TSpef[float]
s.x = 0.4
s.y = 0.6

