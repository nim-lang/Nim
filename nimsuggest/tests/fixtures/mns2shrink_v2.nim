# `ns2shrink` after `tns2_stale_root.nim` dropped most of it.
type
  Thing* = object
    x*: int

proc makeThing*(x: int): Thing =
  Thing(x: x)
