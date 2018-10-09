discard """
  file: "t5965_1.nim"
  line: 10
  errormsg: "incorrect object construction syntax"
"""

type Foo = object
  a, b, c: int

discard Foo(a: 1, 2)
