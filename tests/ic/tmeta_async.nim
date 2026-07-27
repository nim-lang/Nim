discard """
  description: '''metamorphic IC: async/await across an edit (continuations + clean==incremental)'''
"""

# Async is the most cache-fragile area under `nim ic`: the `{.async.}` transform
# generates continuation closures and lifts environments, and those lowered
# bodies must survive incremental edits and converge to exactly what a clean
# build produces. This drives an edit to an async proc body and asserts the
# importer is NOT rebuilt (the lifted continuation stays local to its module),
# a no-op changes nothing, and the final state is byte-identical to a clean
# build. See doc/ic_ideas.md and [[ic-nimbus-test]] (async was the long pole).

#? metamorphic

#!FILE worker.nim
import std/asyncdispatch
proc compute*(x: int): Future[int] {.async.} =
  await sleepAsync(0)
  result = x * 2

#!FILE main.nim
import std/asyncdispatch, worker
echo waitFor compute(21)

#!STEP expect: 42

# --- edit the async proc body. The continuation env lives in `worker`, so only
#     `worker` rebuilds; `main` (the caller) is left untouched -> modules: 1.
#     (An async body edit does perturb `worker`'s interface cookie via the
#     generated env type, so this is not asserted as a pure `body-edit`.)
#!FILE worker.nim
import std/asyncdispatch
proc compute*(x: int): Future[int] {.async.} =
  await sleepAsync(0)
  result = x * 3

#!STEP expect: 63; modules: 1

# --- re-emit identical content: nothing may change, lifted closures included.
#!FILE worker.nim
import std/asyncdispatch
proc compute*(x: int): Future[int] {.async.} =
  await sleepAsync(0)
  result = x * 3

#!STEP expect: 63; noop
