discard """
  line: 11
  errormsg: "undeclared identifier: \'v\'"
"""

import macros

macro log(): untyped =
  let v = 10
  # The variable `v` is _not_ captured
  result = quote do:
    v

discard log()
