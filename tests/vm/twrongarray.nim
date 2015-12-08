discard """
  file: "twrongarray.nim"
  errormsg: "cannot evaluate at compile time: size"
  line: 17
"""

#bug #1343

when false:
  proc one(dummy: int, size: int) =
    var x: array[size, int] # compile error: constant expression expected

  proc three(size: int) =
    var x: array[size * 1, int] # compile error: cannot evaluate at compile time: size

proc two(dummy: int, size: int) =
  var x: array[size * 1, int] # compiles, but shouldn't?
  #doAssert(x.len == size) # just for fun
