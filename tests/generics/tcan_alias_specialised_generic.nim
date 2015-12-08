discard """
  file: "tcan_alias_specialised_generic.nim"
  disabled: false
"""

##
## can_alias_specialised_generic Nim Module
##
## Created by Eric Doughty-Papassideris on 2011-02-16.

type
  TGen[T] = object
  TSpef = TGen[string]

var
  s: TSpef

