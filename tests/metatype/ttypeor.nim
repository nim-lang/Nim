discard """
  file: "ttypeor.nim"
  output: '''Foo
Bar'''
"""

# bug #3338

type
  Base[T] = Foo[T] | Bar[T]

  Foo[T] = ref object
    x: T

  Bar[T] = ref object
    x: T

proc test[T](ks: Foo[T], x, y: T): T =
  echo("Foo")
  return x + y + ks.x

proc test[T](ks: Bar[T], x, y: T): T =
  echo("Bar")
  return x

proc add[T](ksa: Base[T]) =
  var test = ksa.test(5, 10)
  ksa.x = test

var t1 = Foo[int32]()
t1.add()
doAssert t1.x == 15

var t2 = Bar[int32]()
t2.add()
doAssert t2.x == 5
