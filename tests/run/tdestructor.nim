discard """
  output: '''----
myobj constructed
myobj destructed
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
'''
"""

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

proc destruct(o: var TMyObj) {.destructor.} =
  if o.p != nil: dealloc o.p
  echo "myobj destroyed"

proc destroy(o: var TMyGeneric1) {.destructor.} =
  echo "mygeneric1 destroyed"

proc destroy[A, B](o: var TMyGeneric2[A, B]) {.destructor.} =
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
  var
    a = open()
    b = TMyGeneric2[int, T](x: 10, y: val)
    c = TMyGeneric3[int, int, string](x: 10, y: 20, z: "test")

  echo "mygeneric2 constructed"

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

