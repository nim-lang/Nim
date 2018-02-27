discard """
  output: '''
x
e
'''
"""

import asyncjs

# demonstrate forward definition
# for js
proc y(e: int): Future[string] {.async.}

proc e: int {.discardable.} =
  echo "e"
  return 2

proc x(e: int): Future[void] {.async.} =
  var s = await y(e)
  if e > 2:
    return
  echo s
  e()

proc y(e: int): Future[string] {.async.} =
  if e > 0:
    return await y(0)
  else:
    return "x"


discard x(2)

