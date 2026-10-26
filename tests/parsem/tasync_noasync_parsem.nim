discard """
  cmd: "nim check --parsem:on --experimental:strictEffects --hints:off --warnings:off $file"
  action: "reject"
  nimout: '''
tasync_noasync_parsem.nim(33, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(42, 8) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(23, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(27, 12) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(30, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(37, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync_parsem.nim(40, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
'''
"""
# `--parsem:on` variant of tests/async/tasync_noasync: the macro body (header
# pass) and the top-level `await` are reported first, routine bodies after.
import async

proc a {.async.} =
  discard

# Bad await usage
proc nonAsyncProc =
  await a()

proc nestedNonAsyncProc {.async.} =
  proc nested =
    await a()

iterator customIterator: int =
  await a()

macro awaitInMacro =
  await a()

type DummyRef = ref object of RootObj
method awaitInMethod(_: DummyRef) {.base.} =
  await a()

proc improperMultisync {.multisync.} =
  await a()

await a()

# if we overload a fallback handler to get
# await only available within {.async.}
# we would need `{.dirty.}` templates for await
