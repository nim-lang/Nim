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
static: assert(f.y.type.name == "string")

when compiles(f.z):
  {.error: "Foo should not have a `z` field".}

proc p(a, b) =
  when a.type is int:
    static: assert false

  var f: TFoo[m(a.type), b.type]
  static:
    assert f.x.type.name == "int"
    echo  f.y.type.name
    assert f.y.type.name == "float"
    echo  f.z.type.name
    assert f.z.type.name == "float"

p(A, f)

