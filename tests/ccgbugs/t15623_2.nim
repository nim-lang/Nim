# bug #15623
block:
  doAssert cast[int](cast[ptr int](nil)) == 0

block:
  var x: ref int = nil
  doAssert cast[int](cast[ptr int](x)) == 0
