discard """
  errormsg: "annotation to deprecated not supported here"
  line: 8
"""

type
  A = enum
    a {.deprecated: "njshd".}

var v1 = a
