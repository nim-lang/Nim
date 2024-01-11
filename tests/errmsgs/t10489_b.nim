discard """
errormsg: "invalid type: 'macro (body: untyped): untyped{.noSideEffect, gcsafe, raises: <inferred> [].}' for const. Did you mean to call the macro with '()'?"
line: 9
"""

macro m(body: untyped): untyped =
  body

const x2 = m
