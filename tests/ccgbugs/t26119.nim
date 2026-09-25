discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:orc"
  ccodeCheck: "\\i !@('W T' \\d+ '_;')"
"""

type W {.exportc.} = object
  data: array[1000, byte]
  items: seq[int]

# bug #26119: assigning a try expression directly to the result must not leave
# an unused temporary of the result type in the generated procedure.
proc y(): W {.exportc.} =
  try:
    default(W)
  except CatchableError:
    default(W)

var v = y()
doAssert v.data[0] == 0 and v.items.len == 0
