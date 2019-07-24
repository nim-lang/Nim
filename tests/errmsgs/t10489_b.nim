discard """
errormsg: "cannot assign macro symbol to constant here"
line: 9
"""

macro m(body: untyped): untyped =
  body

const x2 = m
