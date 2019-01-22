discard """
  output: '''-1abc'''
"""

var
  a {.compileTime.} = 2
  b = -1
  c {.compileTime.} = 3
  d = "abc"

static:
  assert a == 2
  assert c == 3

echo b, d
