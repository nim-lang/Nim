discard """
  output: "317"
"""

# bug #2599

import mbind_bracket

# also test that `[]` can be passed now as a first class construct:

template takeBracket(x, a, i: untyped) =
  echo x(a, i)

var a: array[10, int]
a[8] = 317

takeBracket(`[]`, a, 8)

let reg = newRegistry[UUIDObject]()
reg.register(UUIDObject())
