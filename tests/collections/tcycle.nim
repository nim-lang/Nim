import sequtils

# cycle tests
let
  a = @[1, 2, 3]
  b: seq[int] = @[]

doAssert a.cycle(3) == @[1, 2, 3, 1, 2, 3, 1, 2, 3]
doAssert a.cycle(0) == @[]
#doAssert a.cycle(-1) == @[] # will not compile!
doAssert b.cycle(3) == @[]
