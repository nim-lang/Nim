discard """
output: '''6 9'''
"""

# Two modules each declare a `type Level = object` inside a proc. A
# proc-local type's owner is the proc, so its key had no module: both were
# `Level.0.` and `seq[Level]` here got mlocaltypekey's `=destroy`, which
# takes a seq of the other `Level` (an incompatible argument in the C code).
import mlocaltypekey

proc fb(n: int): int =
  type Level = object
    g: int
    shown: bool
    push: int
  var open: seq[Level]
  for i in 0..<n: open.add Level(g: i, shown: true, push: 2)
  for x in open: result += x.g + x.push

echo fa(3), " ", fb(3)
