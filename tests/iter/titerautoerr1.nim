discard """
  errormsg: "type mismatch: got <int literal(1)> but expected 'string'"
  line: 8
"""

iterator a(): auto {.closure.} =
  if true: return "str"
  yield 1
