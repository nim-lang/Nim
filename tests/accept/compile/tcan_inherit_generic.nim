##
## can_inherit_generic Nimrod Module
##
## Created by Eric Doughty-Papassideris on 2011-02-16.
## Copyright (c) 2011 FWA. All rights reserved.

type
  TGen[T] = object
  TSpef[T] = object of TGen[T]

