discard """
  output: '''
x
e
'''
"""

import asyncjs

block:
  # demonstrate forward definition for js
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

import sugar
block:
  proc fn(n: int): Future[int] {.async.} =
    if n > 0:
      var ret = 1 + await fn(n-1)
      echo ret
      return ret
    else:
      return 10
  discard fn(4)
  var witness: seq[string]
  discard fn(4).
    then((a: int) => (witness.add $a; a.float*2)).then((a: float) => (witness.add $a)).then(()=>(echo witness)).then(()=>1)
