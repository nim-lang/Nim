# static types that depend on a generic parameter

block: # issue #19365
  var ss: seq[string]
  proc f[T](x: static T) =
    ss.add($x & ": " & $T)

  f(123)
  doAssert ss == @["123: int"]
  f("abc")
  doAssert ss == @["123: int", "abc: string"]
