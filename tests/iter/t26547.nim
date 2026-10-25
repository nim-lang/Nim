discard """
  action: run
"""

# bug #26547
doAssert typeof([0].items) is int
doAssert [0].items.typeof is int
static:
  doAssert typeof([0].items) is int
  doAssert [0].items.typeof is int

let a = @[1, 2]
doAssert a.items.typeof is int
doAssert a.pairs.typeof is (int, int)
