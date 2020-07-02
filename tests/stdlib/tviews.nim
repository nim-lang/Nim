import std/views
from std/sequtils import toSeq

block:
  var a = @[1,2,3]
  let v = a.view()
  doAssert toSeq(v) == a
  doAssert v[1] == 2

block:
  var a = @[1,2,3,4]
  # let v = a.view()[1..^1] # TODO
  let v = a.view()[1..a.len-2]
  doAssert toSeq(v) == @[2,3]
  doAssert v[0] == 2
  # doAssert v[^1] == 3 # TODO
