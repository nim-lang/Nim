
import hotcodereloading

import nimhcr_1 # only importing 1

let g_0 = 1000 # new value! but also a "new" global :)

proc getInt*(): int = return g_0

proc makeCounter*(): auto =
  return iterator: int {.closure.} =
    for i in countup(0, 10, 1):
      yield i

let c = makeCounter()

afterCodeReload:
  echo "   0: after - closure iterator! after reload! does it remember? :", c()
  echo "   0: after - closure iterator! after reload! does it remember? :", c()
