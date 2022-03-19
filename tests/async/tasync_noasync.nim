discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  nonAsyncProc
tasync_noasync.nim(42, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  nested
tasync_noasync.nim(44, 27) template/generic instantiation of `async` from here
tasync_noasync.nim(46, 11) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  customIterator
tasync_noasync.nim(49, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  awaitInMacro
tasync_noasync.nim(52, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  improperMultisync
tasync_noasync.nim(54, 26) template/generic instantiation of `multisync` from here
tasync_noasync.nim(55, 9) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
stack trace: (most recent call last)
asyncmacro.nim(153, 19)  tasync_noasync
tasync_noasync.nim(57, 7) template/generic instantiation of `await` from here
../../lib/pure/asyncmacro.nim(153, 19) Error: Can only 'await' inside a 'async' marked proc.
'''
  nimoutFull: true
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
