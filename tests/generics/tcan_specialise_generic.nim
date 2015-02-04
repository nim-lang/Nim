##
## can_specialise_generic Nim Module
##
## Created by Eric Doughty-Papassideris on 2011-02-16.
## Copyright (c) 2011 FWA. All rights reserved.

type
  TGen[T] = object {.inheritable.}
  TSpef = object of TGen[string]


