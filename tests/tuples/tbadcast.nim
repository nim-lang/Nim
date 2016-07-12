discard """
  file: "tbadcast.nim"
  line: 12
  errormsg: "conversion from tuple[strings: seq[empty], ints: seq[empty], chars: set[empty]] to MyTuple is invalid"
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
