discard """
  exitcode: 0
"""

type
  Enumerable[T] = concept e
    for it in e:
      it is T

proc cmap[T, G](e: Enumerable[T], fn: proc(t: T): G): seq[G] =
  result = @[]
  for it in e: result.add(fn(it))

import json

var x = %["hello", "world"]

var z = x.cmap(proc(it: JsonNode): string = it.getStr & "!")
assert z == @["hello!", "world!"]

