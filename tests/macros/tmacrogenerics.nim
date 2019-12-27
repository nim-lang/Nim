discard """
  nimout: '''
instantiation 1 with typeDesc[int] and typeDesc[float]
instantiation 2 with typeDesc[float] and typeDesc[string]
instantiation 3 with typeDesc[string] and typeDesc[string]
counter: 3
'''
  output: "int\nfloat\nint\nstring"
"""

import typetraits, macros

var counter {.compileTime.} = 0

macro makeBar(A, B: typedesc): typedesc =
  inc counter
  echo "instantiation ", counter, " with ", A.getTypeInst.repr, " and ", B.getTypeInst.repr
  result = A

type
  Bar[T, U] = makeBar(T, U)

var bb1: Bar[int, float]
var bb2: Bar[float, string]
var bb3: Bar[int, float]
var bb4: Bar[string, string]

proc match(a: int)    = echo "int"
proc match(a: string) = echo "string"
proc match(a: float)  = echo "float"

match(bb1)
match(bb2)
match(bb3)
match(bb4)

static:
  echo "counter: ", counter
