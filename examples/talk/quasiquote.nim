
import macros

macro check(ex: expr): stmt =
  var info = ex.lineinfo
  var expString = ex.toStrLit
  result = quote do:
    if not `ex`:
      echo `info`, ": Check failed: ", `expString`

check 1 < 2
