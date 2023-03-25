discard """
  errormsg: "The object construction is given more fields than required"
  file: "t5965_2.nim"
  line: 10
"""

type Foo = object
  a: int

discard Foo(a: 1, 2)
