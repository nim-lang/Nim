discard """
  errormsg: "type mismatch: obtained <string> expected 'int literal(1)'"
  line: 8
"""

iterator b(): auto {.closure.} =
  yield 1
  if true: return "str"
