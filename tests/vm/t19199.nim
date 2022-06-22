# bug #19199
proc mikasa(x: float) = doAssert x == 42

static:
  mikasa 42.uint.float
mikasa 42.uint.float
