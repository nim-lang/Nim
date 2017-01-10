# Bug 4479

type
  MyTuple = tuple
    num: int
    strings: seq[string]
    ints: seq[int]

var foo = MyTuple((
  num: 7,
  strings: @[],
  ints: @[],
))

var bar = (
  num: 7,
  strings: @[],
  ints: @[],
).MyTuple

var fooUnnamed = MyTuple((7, @[], @[]))
var n = 7
var fooSym = MyTuple((num: n, strings: @[], ints: @[]))
