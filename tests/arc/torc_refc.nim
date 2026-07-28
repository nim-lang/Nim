discard """
  matrix: "--mm:orc; --mm:refc"
"""

type M = object
  y: seq[int]
proc `=copy`(_: var M, _: M) {.error.}
proc `=dup`(_: M): M {.error.}
proc k(v: sink M): M = v
proc w() =
  var t = M(y: @[0])
  let s = addr t.y[0]
  t = k(t)
  s[] = 1
  doAssert t.y[0] != 0
w()