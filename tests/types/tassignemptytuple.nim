discard """
  errormsg: "invalid type: 'empty' in this context: '(seq[empty], (seq[empty], set[empty]))' for let"
  file: "tassignemptytuple.nim"
  line: 11
"""

var
  foo: seq[int]
  bar: tuple[a: seq[int], b: set[char]]

(foo, bar) = (@[], (@[], {}))
