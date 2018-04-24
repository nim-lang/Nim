discard """
  output: '''Concrete '='
Concrete '='
Concrete '='
Concrete '='
Concrete '='
GenericT[T] '=' int
GenericT[T] '=' float
GenericT[T] '=' float
GenericT[T] '=' float
GenericT[T] '=' string
GenericT[T] '=' int8
GenericT[T] '=' bool
GenericT[T] '=' bool
GenericT[T] '=' bool
GenericT[T] '=' bool'''
  disabled: "true"
"""

import typetraits

type
  Concrete = object
    a, b: string

proc `=`(d: var Concrete; src: Concrete) =
  shallowCopy(d.a, src.a)
  shallowCopy(d.b, src.b)
  echo "Concrete '='"

var x, y: array[0..2, Concrete]
var cA, cB: Concrete

var cATup, cBTup: tuple[x: int, ha: Concrete]

x = y
cA = cB
cATup = cBTup

type
  GenericT[T] = object
    a, b: T

proc `=`[T](d: var GenericT[T]; src: GenericT[T]) =
  shallowCopy(d.a, src.a)
  shallowCopy(d.b, src.b)
  echo "GenericT[T] '=' ", type(T).name

var ag: GenericT[int]
var bg: GenericT[int]

ag = bg

var xg, yg: array[0..2, GenericT[float]]
var cAg, cBg: GenericT[string]

var cATupg, cBTupg: tuple[x: int, ha: GenericT[int8]]

xg = yg
cAg = cBg
cATupg = cBTupg

var caSeqg, cbSeqg: seq[GenericT[bool]]
newSeq(cbSeqg, 4)
caSeqg = cbSeqg

when false:
  type
    Foo = object
      case b: bool
      of false: xx: GenericT[int]
      of true: yy: bool

  var
    a, b: Foo
  a = b
