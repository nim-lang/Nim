discard """
  file: "tasynctry.nim"
  exitcode: 0
  output: '''
Generic except
Specific except
Multiple idents in except
Multiple except branches
Multiple except branches 2
'''
"""
import asyncdispatch

# Here we are testing the ability to catch exceptions.

proc foobar() {.async.} =
  if 5 == 5:
    raise newException(EInvalidIndex, "Test")

proc catch() {.async.} =
  # TODO: Create a test for when exceptions are not caught.
  try:
    await foobar()
  except:
    echo("Generic except")

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

asyncCheck catch()
