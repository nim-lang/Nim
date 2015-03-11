discard """
  file: "tconsttypemismatch.nim"
  line: 7
  errormsg: "type mismatch"
"""
# bug #2252
const foo: int = 1000 / 30

