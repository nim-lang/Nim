discard """
  description: '''IC: two callers of one `{.dynlib.}` import share a single `Dl_*` definition'''
"""

# Under the per-module backend EVERY TU that calls a `{.dynlib.}` proc emits the
# `Dl_*` function pointer it is called through: `findPendingModule` routes the
# symbol to the demanding module whenever its owner sits outside this process's
# batch. Nothing marked that definition for the merge stage, so two callers put
# the same file-scope symbol into two `.c` and the link failed with "multiple
# definition of `Dl_486539272_'". Found on Windows, where `tests/ic/tmeta_async`
# drags two `os` modules through one winlean import; it reproduces anywhere the
# moment a second module calls the same dynlib symbol.

#? metamorphic

#!FILE lib.nim
when defined(windows):
  const libcName = "msvcrt.dll"
elif defined(macosx):
  const libcName = "libSystem.dylib"
else:
  const libcName = "libc.so.6"

proc catoi*(s: cstring): cint {.importc: "atoi", dynlib: libcName.}

#!FILE a.nim
import lib
proc fromA*(): int = int(catoi("40")) + 1

#!FILE b.nim
import lib
proc fromB*(): int = int(catoi("40")) + 2

#!FILE main.nim
import a, b
echo fromA(), " ", fromB()

#!STEP expect: 41 42

# --- edit one caller. The other still claims the same `Dl_*`, so the merge
#     stage has to keep assigning it exactly one owner across the rebuild.
#!FILE a.nim
import lib
proc fromA*(): int = int(catoi("40")) + 3

#!STEP expect: 43 42; modules: 1
