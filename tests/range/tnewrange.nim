discard """
  targets: "c cpp js"
"""

block:
  var x: range[1 ..< 12] = 4

  var stuff: array[0 ..< 1024, int]

  doAssert stuff[0 ..< 3] == [0, 0, 0]

  doAssert stuff.len == 1024
  doAssert $typeof(x) == "range 1..11(int)"
  doAssert $typeof(stuff) == "array[0..1023, int]"

block:
  var y: 1..<13 = 12
  doAssert $typeof(y) == "range 1..12(int)"
  doAssert y == 12

block:
  var x = @[1, 4, 5, 6, 7, 8]
  doAssert x[0..<3] == @[1, 4, 5]

block:
  var y: range[1..<13] = 11
  doAssert $typeof(y) == "range 1..12(int)"
  doAssert y == 11