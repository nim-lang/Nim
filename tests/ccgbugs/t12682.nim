discard """
  action: compile
"""

template foo*(): untyped =
  var c1 = locals()
  1

proc testAll()=
  doAssert foo() == 1
  let c2=locals()

testAll()