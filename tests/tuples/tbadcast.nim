discard """
  file: "tbadcast.nim"
  line: 13
  errormsg: "cannot infer the type of the sequence"
"""
type
  MyTuple = tuple
    strings: seq[string]
    ints: seq[int]
    chars: set[char]

var foo = MyTuple((
  strings: @[],
  ints: @[],
  chars: {}
))
