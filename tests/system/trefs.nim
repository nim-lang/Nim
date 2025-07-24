discard """
  targets: "c js"
"""

# bug #21317
proc parseHook*(v: var ref int) =
  var a: ref int
  new(a)
  a[] = 123
  v = a

proc fromJson2*(): ref int =
  parseHook(result)

doAssert fromJson2()[] == 123
