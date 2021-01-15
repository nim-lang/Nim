discard """
  disabled: true
"""

import typetraits

type
  TRecord = (tuple) or (object)

  TFoo[T, U] = object
    x: int

    when T is string:
      y: float
    else:
      y: string

    when U is TRecord:
      z: float

  E = enum A, B, C

macro m(t: typedesc): typedesc =
  if t is enum:
    result = string
  else:
    result = int

var f: TFoo[int, int]
static: doAssert(f.y.type.name == "string")

when compiles(f.z):
  {.error: "Foo should not have a `z` field".}

proc p(a, b: auto) =
  when a.type is int:
    static: doAssert false

  var f: TFoo[m(a.type), b.type]
  static:
    doAssert f.x.type.name == "int"
    echo  f.y.type.name
    doAssert f.y.type.name == "float"
    echo  f.z.type.name
    doAssert f.z.type.name == "float"

p(A, f)

