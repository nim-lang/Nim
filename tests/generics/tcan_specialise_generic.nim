discard """
  file: "tcan_specialise_generic.nim"
"""
##
## can_specialise_generic Nim Module
##
## Created by Eric Doughty-Papassideris on 2011-02-16.

type
  TGen[T] = object {.inheritable.}
  TSpef = object of TGen[string]


