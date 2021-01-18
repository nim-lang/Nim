discard """
  errormsg: "`{.union.}` is not implemented for js backend."
"""

type Foo {.union.} = object
  as_bytes: array[8, int8]
  data: int64
