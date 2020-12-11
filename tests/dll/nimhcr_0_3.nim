
import hotcodereloading

import nimhcr_1
import nimhcr_2 # a new and different import!

proc makeCounter*(): auto =
  return iterator: int {.closure.} =
    for i in countup(0, 10, 1):
      yield i

let c = makeCounter()

afterCodeReload:
  echo "   0: after - closure iterator: ", c()
  echo "   0: after - closure iterator: ", c()
  echo "   0: after - c_2 = ", c_2

proc getInt*(): int = return g_1 + g_2.len
