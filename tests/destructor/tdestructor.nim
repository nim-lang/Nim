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
mygeneric1 destroyed
----
myobj destroyed
----
----
myobj destroyed
'''
"""

{.experimental.}

type
  TMyObj = object
    x, y: int
    p: pointer

  TMyGeneric1[T] = object
    x: T

  TMyGeneric2[A, B] = object
    x: A
    y: B

  TMyGeneric3[A, B, C] = object
    x: A
    y: B
    z: C

  TObjKind = enum A, B, C, D

  TCaseObj = object
    case kind: TObjKind
    of A:
      x: TMyGeneric1[int]
    of B, C:
      y: TMyObj
    else:
      case innerKind: TObjKind
      of A, B, C:
        p: TMyGeneric3[int, float, string]
      of D:
        q: TMyGeneric3[TMyObj, int, int]
      r: string

proc destroy(o: var TMyObj) {.override.} =
  if o.p != nil: dealloc o.p
  echo "myobj destroyed"

proc destroy(o: var TMyGeneric1) {.override.} =
  echo "mygeneric1 destroyed"

proc destroy[A, B](o: var TMyGeneric2[A, B]) {.override.} =
  echo "mygeneric2 destroyed"

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

echo "----"
myobj()

echo "----"
mygeneric1()

echo "----"
mygeneric2[int](10)

echo "----"
mygeneric3()

proc caseobj =
  block:
    echo "----"
    var o1 = TCaseObj(kind: A, x: TMyGeneric1[int](x: 10))

  block:
    echo "----"
    var o2 = TCaseObj(kind: B, y: open())

  block:
    echo "----"
    var o3 = TCaseObj(kind: D, innerKind: B, r: "test",
                      p: TMyGeneric3[int, float, string](x: 10, y: 1.0, z: "test"))

  block:
    echo "----"
    var o4 = TCaseObj(kind: D, innerKind: D, r: "test",
                      q: TMyGeneric3[TMyObj, int, int](x: open(), y: 1, z: 0))

caseobj()

