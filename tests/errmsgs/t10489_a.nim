discard """
errormsg: "invalid type: 'macro (body: untyped): untyped{.noSideEffect, gcsafe, locks: 0.}' for let. Did you mean to call the macro with '()'?"
line: 9
"""

macro m(body: untyped): untyped =
  body

let x1 = m
