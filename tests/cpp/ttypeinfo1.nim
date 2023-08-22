discard """
  targets: "cpp"
  output: '''100'''
"""

import typeinfo

#bug #6016
type
  Onion {.union.} = object
    field1: int
    field2: uint64

  Stroom  = Onion

  PStroom = ptr Stroom

proc pstruct(u: PStroom) =
  echo u.field2

var x = Onion(field1: 100)
pstruct(x.addr)