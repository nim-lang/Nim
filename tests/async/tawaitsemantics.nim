discard """
  file: "tawaitsemantics.nim"
  exitcode: 0
  output: '''
Error caught
Test infix
Test call
'''
"""

import asyncdispatch

# This tests the behaviour of 'await' under different circumstances.
# For example, when awaiting Future variable and this future has failed the
# exception shouldn't be raised as described here
# https://github.com/nim-lang/Nim/issues/4170

proc thrower(): Future[void] =
  result = newFuture[void]()
  result.fail(newException(Exception, "Test"))

proc dummy: Future[void] =
  result = newFuture[void]()
  result.complete()

proc testInfix() {.async.} =
  # Test the infix operator semantics.
  var fut = thrower()
  var fut2 = dummy()
  await fut or fut2 # Shouldn't raise.
  # TODO: what about: await thrower() or fut2?

proc testCall() {.async.} =
  await thrower()

proc tester() {.async.} =
  # Test that we can handle exceptions without 'try'
  var fut = thrower()
  doAssert fut.finished
  doAssert fut.failed
  doAssert fut.error.msg == "Test"
  await fut # We are awaiting a 'Future', so no `read` occurs.
  doAssert fut.finished
  doAssert fut.failed
  doAssert fut.error.msg == "Test"
  echo("Error caught")

  fut = testInfix()
  await fut
  doAssert fut.finished
  doAssert(not fut.failed)
  echo("Test infix")

  fut = testCall()
  await fut
  doAssert fut.failed
  echo("Test call")

waitFor(tester())
