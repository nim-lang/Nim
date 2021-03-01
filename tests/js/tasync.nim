discard """
  output: '''
x
e
done
'''
"""

#[
xxx move this to tests/stdlib/tasyncjs.nim
]#

import std/asyncjs

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

import std/sugar
from std/strutils import contains

var witness: seq[string]

proc fn(n: int): Future[int] {.async.} =
  if n >= 7:
    raise newException(ValueError, "foobar: " & $n)
  if n > 0:
    var ret = 1 + await fn(n-1)
    witness.add $(n, ret)
    return ret
  else:
    return 10

proc main() {.async.} =
  block: # then
    let x = await fn(4)
      .then((a: int) => a.float)
      .then((a: float) => $a)
    doAssert x == "14.0"
    doAssert witness == @["(1, 11)", "(2, 12)", "(3, 13)", "(4, 14)"]

    doAssert (await fn(2)) == 12

    let x2 = await fn(4).then((a: int) => (discard)).then(() => 13)
    doAssert x2 == 13

  block: # catch
    var reason: Error
    await fn(6).then((a: int) => (witness.add $a)).catch((r: Error) => (reason = r))
    doAssert reason == nil

    await fn(7).then((a: int) => (discard)).catch((r: Error) => (reason = r))
    doAssert reason != nil
    doAssert reason.name == "Error"
    doAssert "foobar: 7" in $reason.message
  echo "done" # justified here to make sure we're running this, since it's inside `async`

discard main()
