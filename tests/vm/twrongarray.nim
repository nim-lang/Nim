discard """
  errormsg: "cannot evaluate at compile time: size"
  line: 9
"""

#bug #1343

proc two(dummy: int, size: int) =
  var x: array[size * 1, int] # compiles, but shouldn't?
  #assert(x.len == size) # just for fun
