import macros

macro makeVar(): untyped =
  quote:
    var tensorY {.inject.}: int

macro noop(a: typed): untyped =
  a

noop:
  makeVar
echo tensorY

