
import hotcodereloading

let g_0 = 42 # lets start with the ultimate answer

proc getInt*(): int = return g_0

programResult = 0 # should be accessible

beforeCodeReload:
  echo "   0: before"
afterCodeReload:
  echo "   0: after"
  