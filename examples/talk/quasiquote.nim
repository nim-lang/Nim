
import macros

macro check(ex: untyped): typed =
  var info = ex.lineinfo
  var expString = ex.toStrLit
  result = quote do:
    if not `ex`:
      echo `info`, ": Check failed: ", `expString`

check 1 < 2
