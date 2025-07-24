discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout: '''
tasync_noasync.nim(21, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(25, 12) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(28, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(31, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(35, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(38, 10) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
tasync_noasync.nim(40, 8) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
'''
"""
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
