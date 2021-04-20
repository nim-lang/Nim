discard """
  targets: "c cpp js"
"""

import std/typetraits



macro testClosure(fn: typed, flag: static bool) =
  if flag:
    doAssert hasClosure(fn)
  else:
    doAssert not hasClosure(fn)

block:
  proc h1() =
    echo 1

  testClosure(h1, false)

  proc h2() {.nimcall.} =
    echo 2

  testClosure(h2, false)


block:
  proc fn(): auto =
    proc hello() {.nimcall.} =
      echo 3
    hello

  let name = fn()
  testClosure(name, false)

block:
  proc fn(): auto =
    proc hello() =
      echo 3
    hello

  let name = fn()
  testClosure(name, false)

block:
  proc fn(): auto =
    var x = 0
    proc hello() =
      echo 3
      inc x
    hello

  let name = fn()
  testClosure(name, true)

block:
  proc fn(): auto =
    var x = 0
    proc hello() {.closure.} =
      echo 3
      inc x
    hello

  let name = fn()
  testClosure(name, true)

block:
  proc fn(): auto =
    var x = 0
    proc hello() {.closure.} =
      echo 3
      inc x
    hello

  let name = fn()
  testClosure(name, true)

  let name2 = name
  testClosure(name2, true)

block:
  iterator hello(): int =
    yield 1

  testClosure(hello, false)

when not defined(js):
  block:
    iterator hello(): int {.closure.}=
      yield 1

    testClosure(hello, true)
