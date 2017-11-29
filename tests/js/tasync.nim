discard """
  disabled: true
  output: '''
0
x
'''
"""

import asyncjs

proc y(e: int): Future[string] {.async.} =
  echo 0
  return "x"

proc x(e: int) {.async.} =
  var s = await y(e)
  echo s

discard x(2)

