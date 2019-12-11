discard """
errormsg: "cannot assign macro 'm' to 'x1'. Did you mean to call the macro with '()'?"
line: 9
"""

macro m(body: untyped): untyped =
  body

let x1 = m
