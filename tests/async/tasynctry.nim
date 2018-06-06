discard """
  file: "tasynctry.nim"
  exitcode: 0
  output: '''
Generic except: Test
Specific except
Multiple idents in except
Multiple except branches
Multiple except branches 2
'''
"""
import asyncdispatch, strutils

# Here we are testing the ability to catch exceptions.

proc foobar() {.async.} =
  if 5 == 5:
    raise newException(EInvalidIndex, "Test")

proc catch() {.async.} =
  # TODO: Create a test for when exceptions are not caught.
  try:
    await foobar()
  except:
    echo("Generic except: ", getCurrentExceptionMsg().splitLines[0])

  try:
    await foobar()
  except EInvalidIndex:
    echo("Specific except")

  try:
    await foobar()
  except OSError, EInvalidField, EInvalidIndex:
    echo("Multiple idents in except")

  try:
    await foobar()
  except OSError, EInvalidField:
    assert false
  except EInvalidIndex:
    echo("Multiple except branches")

  try:
    await foobar()
  except EInvalidIndex:
    echo("Multiple except branches 2")
  except OSError, EInvalidField:
    assert false

waitFor catch()

proc test(): Future[bool] {.async.} =
  result = false
  try:
    raise newException(OSError, "Foobar")
  except:
    result = true
    return

proc foo(): Future[bool] {.async.} = discard

proc test2(): Future[bool] {.async.} =
  result = false
  try:
    discard await foo()
    raise newException(OSError, "Foobar")
  except:
    result = true
    return

proc test3(): Future[int] {.async.} =
  result = 0
  try:
    try:
      discard await foo()
      raise newException(OSError, "Hello")
    except:
      result = 1
      raise
  except:
    result = 2
    return

proc test4(): Future[int] {.async.} =
  try:
    discard await foo()
    raise newException(ValueError, "Test4")
  except OSError:
    result = 1
  except:
    result = 2

var x = test()
assert x.waitFor()

x = test2()
assert x.waitFor()

var y = test3()
assert y.waitFor() == 2

y = test4()
assert y.waitFor() == 2
