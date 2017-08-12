discard """
  file: "t5965_2.nim"
  line: 10
  errormsg: "incorrect object construction syntax"
"""

type Foo = object
  a: int

discard Foo(a: 1, 2)
