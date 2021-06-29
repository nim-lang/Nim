discard """
  errormsg: "type mismatch: obtained <int literal(1)> expected 'string'"
  line: 8
"""

iterator a(): auto {.closure.} =
  if true: return "str"
  yield 1
