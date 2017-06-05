discard """
  output: "Ok 5"
"""

type OffsetEnum* = enum
  oeA = 'a',
  oeB = 'b'

type WithKind = ref object
  case kind: OffsetEnum:
  of oeA:
    foo: int
  else:
    bar: int

var tmp: WithKind
new(tmp)
tmp.kind = oeB
tmp.bar = 5

echo "Ok ", tmp.bar
