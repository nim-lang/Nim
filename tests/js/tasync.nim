discard """
  disabled: true
  output: '''
0
x
e
'''
"""

import asyncjs

# demonstrate forward definition
# for js
proc y(e: int): Future[string]

proc e: int {.discardable.} =
  echo "e"
  return 2

proc x(e: int): Future[void] {.async.} =
  var s = await y(e)
  echo s
  e()

proc y(e: int): Future[string] {.async.} =
  echo 0
  return "x"


discard x(2)

