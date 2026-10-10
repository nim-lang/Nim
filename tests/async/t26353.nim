discard """
  output: "1"
"""

# bug #26353: `i1` collided with the `i` of the inlined `items` in the env
import std/asyncdispatch

proc handler(): Future[int] {.async.} =
  var i1 = 1
  var a, b, c, d, e, f, g, h, j = 0
  await sleepAsync(1)
  result = i1 + a + b + c + d + e + f + g + h + j
  let s = @[1, 2]
  for x in s:
    await sleepAsync(1)

echo waitFor handler()
