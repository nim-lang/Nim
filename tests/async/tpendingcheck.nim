discard """
  output: ""
  joinable:false
"""
#[
joinable:false otherwise:
Error: unhandled exception: tpendingcheck.nim(7, 9) `not hasPendingOperations()`  [AssertionDefect]
xxx seems like a bug
]#

import asyncdispatch

doAssert(not hasPendingOperations())

proc test() {.async.} =
  await sleepAsync(50)

var f = test()
while not f.finished:
  doAssert(hasPendingOperations())
  poll(10)
f.read

doAssert(not hasPendingOperations())
