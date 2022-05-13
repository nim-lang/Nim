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
