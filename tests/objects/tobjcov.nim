discard """
action: compile
targets: "c"
"""

# Covariance is not type safe:
# Note: `nim cpp` makes it a compile error (after codegen), even with:
# `var f = cast[proc (x: var TA) {.nimcall.}](cast[pointer](bp))`, which
# currently removes all the `cast` in cgen'd code, hence the compile error.

type
  TA = object of RootObj
    a: int
  TB = object of TA
    b: array[0..5000_000, int]

proc ap(x: var TA) = x.a = -1
proc bp(x: var TB) = x.b[high(x.b)] = -1

# in Nim proc (x: TB) is compatible to proc (x: TA),
# but this is not type safe:
var f = cast[proc (x: var TA) {.nimcall.}](bp)
var a: TA
f(a) # bp expects a TB, but gets a TA
