import std/asyncdispatch

proc errval {.async.} =
  raise newException(ValueError, "err")
  
proc err {.async.} =
  try:
    doAssert false
  finally:
    echo "finally"
    # removing the following code will propagate the AssertionDefect
    try:
      await errval()
    except ValueError:
      echo "valueError"

proc main {.async.} =
  let errFut = err()
  await errFut

var ok = false
try:
  waitFor main()
except AssertionDefect:
  ok = true

doAssert(ok)
