import macros

macro makeVar(): untyped =
  quote:
    var tensorY {.inject.}: int

macro noop(a: typed): untyped =
  assert false
  a

noop:
  makeVar
echo tensorY

