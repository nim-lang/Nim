discard """
  file: "tassignemptytuple.nim"
  line: 11
  errormsg: "cannot infer the type of the tuple"
"""

var
  foo: seq[int]
  bar: tuple[a: seq[int], b: set[char]]

(foo, bar) = (@[], (@[], {}))
