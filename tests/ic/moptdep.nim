# Helper for `ttryimport`: an ordinary, importable module. NOTHING imports it
# unconditionally — it is reachable ONLY through `mtryimport`'s
# `when compiles((; import moptdep))`. Under whole-program `nim c` the compiler
# loads it on demand to answer the `compiles`, so the import succeeds. Under
# `nim ic` no `.s.bif` is scheduled for a module that only appears inside a
# `compiles`, so the import (and thus `compiles`) must NOT silently report false.

proc optValue*(): string = "optional-present"
