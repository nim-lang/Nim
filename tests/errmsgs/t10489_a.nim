discard """
errormsg: "cannot assign macro symbol to variable here"
line: 9
"""

macro m(body: untyped): untyped =
  body

let x1 = m
