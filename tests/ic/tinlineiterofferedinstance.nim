discard """
  description: "IC: a generic inline iterator instance reused through its home's offer is lowered by the home"
"""

#? metamorphic

# `other` mints `counter[int]` and offers it; `main` reuses that very instance.
# Its nested closure `bump` belongs to `other`, so `other`'s `lower` stage must
# lift the instance, whether or not `other` expands it in a routine that
# `lower` transforms anyway. Each phase hides `other`'s expansion somewhere
# else: a lowered proc, a top-level `for` (transformed in `cg`), an unused
# private proc, a generic proc instance.

#!FILE helper.nim
type Read* = proc(): int

iterator counter*[T](start: T): Read =
  var held = int(start)
  proc bump(): int =
    inc held
    held
  yield bump
  held = held * 10
  yield bump

#!FILE other.nim
import helper
proc fromOther*(): seq[Read] =
  for f in counter(1): result.add f

#!FILE main.nim
import helper, other
proc run() =
  var mine: seq[Read]
  for f in counter(5): mine.add f
  let theirs = fromOther()
  echo mine[0](), " ", mine[1](), " ", theirs[0](), " ", theirs[1]()
  echo rawProc(mine[0]) == rawProc(theirs[0]), " ", rawEnv(mine[0]) == rawEnv(theirs[0])
run()
#!STEP expect: 51 52 11 12\ntrue false
#!STEP
#!STEP noop

# The home expands the instance only at top level.
#!FILE other.nim
import helper
var fromOtherTop: seq[Read]
for f in counter(1): fromOtherTop.add f
proc fromOther*(): seq[Read] = fromOtherTop
#!STEP expect: 51 52 11 12\ntrue false
#!STEP
#!STEP noop

# The home expands the instance only inside a generic proc instance.
#!FILE other.nim
import helper
proc collect[T](start: T): seq[Read] =
  for f in counter(int(start)): result.add f
proc fromOther*(): seq[Read] = collect(1.0)
#!STEP expect: 51 52 11 12\ntrue false
#!STEP
#!STEP noop

# The home expands the instance only inside an unused private proc.
#!FILE other.nim
import helper
proc hidden() =
  for f in counter(1): discard f()
proc fromOther*(): seq[Read] =
  var x = 1
  proc one(): int = x
  result = @[one, one]

#!FILE main.nim
import helper, other
proc run() =
  var mine: seq[Read]
  for f in counter(5): mine.add f
  let theirs = fromOther()
  echo mine[0](), " ", mine[1](), " ", theirs[0](), " ", theirs[1]()
run()
#!STEP expect: 51 52 1 1
#!STEP
#!STEP noop

# A body-only edit grows the offered instance's environment.
#!FILE helper.nim
type Read* = proc(): int

iterator counter*[T](start: T): Read =
  var held = int(start)
  var calls = 0
  proc bump(): int =
    inc held
    inc calls
    held * 100 + calls
  yield bump
  held = held * 10
  yield bump
#!STEP body-edit; expect: 5101 5202 1 1
#!STEP
#!STEP noop
