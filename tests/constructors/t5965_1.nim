discard """
  errormsg: "When mixing named fields and unnamed fields, every field needs to be initialized in order"
  file: "t5965_1.nim"
  line: 10
"""

type Foo = object
  a, b, c: int

discard Foo(a: 1, 2)
