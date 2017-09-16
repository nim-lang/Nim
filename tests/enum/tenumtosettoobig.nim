discard """
  errormsg: "set is too large"
"""

type
  E = enum
    a = 1 shl 16 + 1
discard E.toSet