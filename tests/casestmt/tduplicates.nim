discard """
  output: '''
OK
OK
OK
  '''
"""

type Kind = enum A, B
var k = A

template reject(b) =
  static: doAssert(not compiles(b))

reject:
    var i = 2
    case i
    of [1, 1]: discard
    else: discard

reject:
    var i = 2
    case i
    of 1, { 1..2 }: discard
    else: discard

reject:
    var i = 2
    case i
    of { 1, 1 }: discard
    of { 1, 1 }: discard
    else: discard

reject:
    case k
    of [A, A]: discard

var i = 2
case i
of { 1, 1 }: discard
of { 2, 2 }: echo "OK"
else: discard

case i
of { 10..30, 15..25, 5..15, 25..35 }: discard
else: echo "OK"

case k
of {A, A..A}: echo "OK"
of B: discard