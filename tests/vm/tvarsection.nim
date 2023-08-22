var
  a {.compileTime.} = 2
  b = -1
  c {.compileTime.} = 3
  d = "abc"

static:
  doAssert a == 2
  doAssert c == 3

doAssert ($b & $d) == "-1abc"
