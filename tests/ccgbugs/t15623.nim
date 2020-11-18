# bug #15623
block:
  if false:
    echo cast[ptr int](nil)[]

block:
  if false:
    var x: ref int = nil
    echo cast[ptr int](x)[]

block:
  doAssert cast[int](cast[ptr int](nil)) == 0

block:
  var x: ref int = nil
  doAssert cast[int](cast[ptr int](x)) == 0
