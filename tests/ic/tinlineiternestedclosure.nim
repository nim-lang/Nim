discard """
  description: "IC: a nested closure in another module's inline iterator"
"""

#? metamorphic

# Regression test: under `nim ic`, an inline iterator from another module whose
# body contains a nested closure capturing a local failed in the backend with
# `internal error: expr: var not init x_<id>`.

#!FILE minlineiternestedclosure.nim
iterator it*(): int =
  var x = 1
  let f = proc(): int = x
  yield f()

#!FILE main.nim
import minlineiternestedclosure

proc run() =
  for y in it():
    echo y

run()
#!STEP expect: 1
