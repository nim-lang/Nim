proc baz(o: any): int = 5 # if bar is exported, it works

type MyObj = object
  x: int

proc foo*(b: any) =
  var o: MyObj
  echo b.baz, " ", o.x.baz, " ", b.baz()
