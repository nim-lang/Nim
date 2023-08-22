proc baz(o: auto): int = 5 # if bar is exported, it works

type MyObj = object
  x: int

proc foo*(b: auto) =
  var o: MyObj
  echo b.baz, " ", o.x.baz, " ", b.baz()

import sets

var intset = initHashSet[int]()

proc fn*[T](a: T) =
  if a in intset: echo("true")
  else: echo("false")

import strutils

proc doStrip*[T](a: T): string =
  result = ($a).strip()

type Foo = int32
proc baz2*[T](y: int): auto =
  result = y.Foo

proc set*(x: var int, a, b: string) =
  x = a.len + b.len
