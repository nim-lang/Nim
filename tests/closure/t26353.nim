discard """
  targets: "c js"
  output: '''
0
3
'''
"""

# bug #26353: env field names `name & $position` collided (`x1` at position 1
# and `x` at position 11 both became `x11`).
iterator it(): int {.closure.} =
  var x1 = 1
  var a, b, c, d, e, f, g, h, i = 0
  var x = 2
  yield 0
  yield x1 + a + b + c + d + e + f + g + h + i + x

for v in it(): echo v

proc outer(): int =
  var y1 = 1
  var a, b, c, d, e, f, g, h, i = 0
  var y = 2
  proc inner(): int = y1 + a + b + c + d + e + f + g + h + i + y
  inner()

doAssert outer() == 3
