discard """
  output: ''''''
"""

type
  MyObj = object
    a: int

proc test_lent(x: MyObj): lent int =
  x.a

proc test_var(x: var MyObj): var int =
  x.a

var x = MyObj(a: 5)

doAssert: test_var(x).addr == x.a.addr
doAssert: test_lent(x).unsafeAddr == x.a.addr

proc varProc(x: var int) =
  x = 100

doAssert: not compiles(test_lent(x) = 1)
doAssert: not compiles(varProc(test_lent(x)))

