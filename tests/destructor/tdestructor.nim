discard """
  output: '''----
myobj constructed
myobj destroyed
----
mygeneric1 constructed
mygeneric1 destroyed
----
mygeneric2 constructed
mygeneric2 destroyed
myobj destroyed
----
mygeneric3 constructed
mygeneric1 destroyed
----
mydistinctObj constructed
myobj destroyed
mygeneric2 destroyed
------------------
----
----
myobj destroyed
myobj destroyed
myobj destroyed
myobj destroyed
mygeneric1 destroyed
---
myobj destroyed
myobj destroyed
myobj destroyed
'''
"""

type
  TMyObj = object
    x, y: int
    p: pointer

proc `=destroy`(o: var TMyObj) =
  if o.p != nil: dealloc o.p
  echo "myobj destroyed"

type
  TMyGeneric1[T] = object
    x: T

  TMyGeneric2[A, B] = object
    x: A
    y: B

proc `=destroy`(o: var TMyGeneric1[int]) =
  echo "mygeneric1 destroyed"

proc `=destroy`[A, B](o: var TMyGeneric2[A, B]) =
  echo "mygeneric2 destroyed"

type
  TMyGeneric3[A, B, C] = object
    x: A
    y: B
    z: C

  TDistinctObjX = distinct TMyGeneric3[TMyObj, TMyGeneric2[int, int], int]
  TDistinctObj = TDistinctObjX

  TObjKind = enum Z, A, B, C, D

  TCaseObj = object
    z: TMyGeneric3[TMyObj, float, int]
    case kind: TObjKind
    of Z: discard
    of A:
      x: TMyGeneric1[int]
    of B, C:
      y: TMyObj
    else:
      case innerKind: TObjKind
      of Z: discard
      of A, B, C:
        p: TMyGeneric3[int, float, string]
      of D:
        q: TMyGeneric3[TMyObj, int, int]
      r: string

proc open: TMyObj =
  # allow for superfluous ()
  result = (TMyObj(x: 1, y: 2, p: alloc(3)))

proc `$`(x: TMyObj): string = $x.y

proc myobj() =
  var x = open()
  echo "myobj constructed"

proc mygeneric1() =
  var x = TMyGeneric1[int](x: 10)
  echo "mygeneric1 constructed"

proc mygeneric2[T](val: T) =
  var a = open()

  var b = TMyGeneric2[int, T](x: 10, y: val)
  echo "mygeneric2 constructed"

  var c = TMyGeneric3[int, int, string](x: 10, y: 20, z: "test")

proc mygeneric3 =
  var x = TMyGeneric3[int, string, TMyGeneric1[int]](
    x: 10, y: "test", z: TMyGeneric1[int](x: 10))

  echo "mygeneric3 constructed"

proc mydistinctObj =
  var x = TMyGeneric3[TMyObj, TMyGeneric2[int, int], int](
    x: open(), y: TMyGeneric2[int, int](x: 5, y: 15), z: 20)

  echo "mydistinctObj constructed"

echo "----"
myobj()

echo "----"
mygeneric1()

echo "----"
mygeneric2[int](10)

echo "----"
mygeneric3()

echo "----"
mydistinctObj()

proc caseobj =
  block:
    var o1 = TCaseObj(kind: A, x: TMyGeneric1[int](x: 10))

  block:
    echo "----"
    var o2 = TCaseObj(kind: B, y: open())

  block:
    echo "----"
    var o3 = TCaseObj(kind: D, innerKind: B, r: "test",
                      p: TMyGeneric3[int, float, string](x: 10, y: 1.0, z: "test"))


echo "------------------"
caseobj()

proc caseobj_test_sink: TCaseObj =
  # check that lifted sink can destroy case val correctly
  result = TCaseObj(kind: D, innerKind: D, r: "test",
                      q: TMyGeneric3[TMyObj, int, int](x: open(), y: 1, z: 0))
  result = TCaseObj(kind: B, y: open())


echo "---"
discard caseobj_test_sink()