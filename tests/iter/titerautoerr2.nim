discard """
  errormsg: "type mismatch: got <string> but expected 'int literal(1)'"
  line: 8
"""

iterator b(): auto {.closure.} =
  yield 1
  if true: return "str"
