discard """
  errormsg: "type mismatch"
  file: "tconsttypemismatch.nim"
  line: 7
"""
# bug #2252
const foo: int = 1000 / 30
