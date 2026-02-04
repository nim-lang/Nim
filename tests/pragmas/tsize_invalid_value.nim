discard """
  errormsg: "size may only be 1, 2, 4 or 8"
  line: 7
"""
## Reject test: size pragma only accepts 1, 2, 4, or 8 for non-imported types

type InvalidSize {.size: 3.} = enum a, b, c
