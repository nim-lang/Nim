# Covariance is not type safe:

type
  TA = object of TObject
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

