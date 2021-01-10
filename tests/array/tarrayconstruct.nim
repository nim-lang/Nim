discard """
  targets: "c cpp js"
"""

block:

  var stuff: array[0 ..< 1024, int]

  doAssert stuff[0 ..< 3] == [0, 0, 0]

  doAssert stuff.len == 1024
  doAssert $typeof(stuff) == "array[0..1023, int]"

block:
  var x = @[1, 4, 5, 6, 7, 8]
  doAssert x[0..<3] == @[1, 4, 5]
