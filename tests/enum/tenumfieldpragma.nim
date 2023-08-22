discard """
  nimout: '''tenumfieldpragma.nim(20, 10) Warning: d is deprecated [Deprecated]
tenumfieldpragma.nim(21, 10) Warning: e is deprecated [Deprecated]
tenumfieldpragma.nim(22, 10) Warning: f is deprecated [Deprecated]
'''
"""

type
  A = enum
    a
    b = "abc"
    c = (10, "def")
    d {.deprecated.}
    e {.deprecated.} = "ghi"
    f {.deprecated.} = (20, "jkl")

var v1 = a
var v2 = b
var v3 = c
var v4 = d
var v5 = e
var v6 = f
