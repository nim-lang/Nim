discard """
  targets: "c js"
  matrix: "--gc:refc; --gc:arc"
"""


template main =
  proc hello(x: varargs[string]): seq[string] =
    var s: seq[string]
    s.add x
    s

  doAssert hello() == @[]
  doAssert hello("a1") == @["a1"]
  doAssert hello("a1", "a2") == @["a1", "a2"]

static: main()
main()
