discard """
  errormsg: "cannot infer the type of the tuple"
  file: "tassignemptytuple.nim"
  line: 11
"""

var
  foo: seq[int]
  bar: tuple[a: seq[int], b: set[char]]

(foo, bar) = (@[], (@[], {}))
