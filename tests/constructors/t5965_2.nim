discard """
  errormsg: "incorrect object construction syntax"
  file: "t5965_2.nim"
  line: 10
"""

type Foo = object
  a: int

discard Foo(a: 1, 2)
