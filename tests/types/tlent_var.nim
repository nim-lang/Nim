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
doAssert: test_lent(x).addr == x.a.addr

proc varProc(x: var int) =
  x = 100

doAssert: not compiles(test_lent(x) = 1)
doAssert: not compiles(varProc(test_lent(x)))

type X = tuple[a: int, b: int]

type ArrayBuf*[N: static int, T] = object
  buf*: array[N, T]

var v: ArrayBuf[32, X]


# proc `[]`*[N, T](b: var ArrayBuf[N, T], i: BackwardsIndex): lent T = # works
#   b.buf[i]

template `[]`*[N, T](b: var ArrayBuf[N, T], i: BackwardsIndex): lent T =
  b.buf[i]

doAssert $v[^4] == "(a: 0, b: 0)"
