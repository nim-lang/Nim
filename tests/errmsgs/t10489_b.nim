discard """
errormsg: "cannot assign macro 'm' to 'x2'. Did you mean to call the macro with '()'?"
line: 9
"""

macro m(body: untyped): untyped =
  body

const x2 = m
