discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout: '''
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  nonAsyncProc
tasync_noasync.nim(47, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  nested
tasync_noasync.nim(49, 27) template/generic instantiation of `async` from here
tasync_noasync.nim(51, 11) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  customIterator
tasync_noasync.nim(54, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  awaitInMacro
tasync_noasync.nim(57, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  awaitInMethod
tasync_noasync.nim(61, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  improperMultisync
tasync_noasync.nim(63, 26) template/generic instantiation of `multisync` from here
tasync_noasync.nim(64, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
stack trace: (most recent call last)
asyncmacro.nim(136, 18)  tasync_noasync
tasync_noasync.nim(66, 7) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(136, 18) Error: Can only 'await' inside a proc marked as 'async'. Use 'waitFor' when calling an 'async' proc in a non-async scope instead
'''
  nimoutFull: true
  disabled: "win"
  file: "asyncmacro.nim"
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


# Good await usage
proc asyncProc {.async.} =
  await a()

proc nestedAsyncProc {.async.} =
  proc nested {.async.} =
    await a()

proc asyncBlock {.async.} =
  block:
    await a()

# if we overload a fallback handler to get
# await only available within {.async.}
# we would need `{.dirty.}` templates for await
