discard """
output: '''
Error can be caught using yield
Infix `or` raises
Infix `and` raises
All() raises
Awaiting a async procedure call raises
Awaiting a future raises
'''
"""

import asyncdispatch

# This tests the behaviour of 'await' under different circumstances.
# Specifically, when an awaited future raises an exception then `await` should
# also raise that exception by `read`'ing that future. In cases where you don't
# want this behaviour, you can use `yield`.
# https://github.com/nim-lang/Nim/issues/4170

proc thrower(): Future[void] =
  result = newFuture[void]()
  result.fail(newException(Exception, "Test"))

proc dummy: Future[void] =
  result = newFuture[void]()
  result.complete()

proc testInfixOr() {.async.} =
  # Test the infix `or` operator semantics.
  var fut = thrower()
  var fut2 = dummy()
  await fut or fut2 # Should raise!

proc testInfixAnd() {.async.} =
  # Test the infix `and` operator semantics.
  var fut = thrower()
  var fut2 = dummy()
  await fut and fut2 # Should raise!

proc testAll() {.async.} =
  # Test the `all` semantics.
  var fut = thrower()
  var fut2 = dummy()
  await all(fut, fut2) # Should raise!

proc testCall() {.async.} =
  await thrower()

proc testAwaitFut() {.async.} =
  var fut = thrower()
  await fut # This should raise.

proc tester() {.async.} =
  # Test that we can handle exceptions without 'try'
  var fut = thrower()
  doAssert fut.finished
  doAssert fut.failed
  doAssert fut.error.msg == "Test"
  yield fut # We are yielding a 'Future', so no `read` occurs.
  doAssert fut.finished
  doAssert fut.failed
  doAssert fut.error.msg == "Test"
  echo("Error can be caught using yield")

  fut = testInfixOr()
  yield fut
  doAssert fut.finished
  doAssert fut.failed
  echo("Infix `or` raises")

  fut = testInfixAnd()
  yield fut
  doAssert fut.finished
  doAssert fut.failed
  echo("Infix `and` raises")

  fut = testAll()
  yield fut
  doAssert fut.finished
  doAssert fut.failed
  echo("All() raises")

  fut = testCall()
  yield fut
  doAssert fut.failed
  echo("Awaiting a async procedure call raises")

  # Test that await will read the future and raise an exception.
  fut = testAwaitFut()
  yield fut
  doAssert fut.failed
  echo("Awaiting a future raises")


waitFor(tester())
