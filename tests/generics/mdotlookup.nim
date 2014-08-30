proc baz(o: any): int = 5 # if bar is exported, it works

type MyObj = object
  x: int

proc foo*(b: any) =
  var o: MyObj
  echo b.baz, " ", o.x.baz, " ", b.baz()

import sets

var intset = initSet[int]()

proc func*[T](a: T) =
  if a in intset: echo("true")
  else: echo("false")
