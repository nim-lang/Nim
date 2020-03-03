discard """
  errormsg: "cannot evaluate at compile time: initArray"
  line: 11
"""

# bug #3066

proc initArray(): array[10, int]

const
  someTable = initArray()

proc initArray(): array[10, int] =
  for f in 0..<10:
    result[f] = 3

when true: echo repr(someTable)
