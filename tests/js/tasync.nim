discard """
  disabled: true
  output: '''
0
x
'''
"""

import asyncjs

# demonstrate forward definition
# for js
proc y(e: int): Future[string]

proc x(e: int) {.async.} =
  var s = await y(e)
  echo s

proc y(e: int): Future[string] {.async.} =
  echo 0
  return "x"



discard x(2)

