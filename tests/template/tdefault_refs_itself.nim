discard """
  errormsg: "the default value of 'color' refers back to 'color'"
  line: 10
"""

type Thing = object
  color: int

# `color` in the default is the param, not the field: expanding it recursed.
template paint(color: untyped = me.color) =
  discard color

let me = Thing(color: 7)
paint()
