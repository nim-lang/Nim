discard """
  file: "tasynctry2.nim"
  errormsg: "\'yield\' cannot be used within \'try\' in a non-inlined iterator"
  line: 17
"""
import asyncdispatch

{.experimental: "oldIterTransf".}

proc foo(): Future[bool] {.async.} = discard

proc test5(): Future[int] {.async.} =
  try:
    discard await foo()
    raise newException(ValueError, "Test5")
  except:
    discard await foo()
    result = 0
