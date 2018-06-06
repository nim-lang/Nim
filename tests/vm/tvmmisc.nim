# bug #4462
import macros
import os
import ospaths
import strutils

block:
  proc foo(t: typedesc) {.compileTime.} =
    assert sameType(getType(t), getType(int))

  static:
    foo(int)

# #4412
block:
  proc default[T](t: typedesc[T]): T {.inline.} = discard

  static:
    var x = default(type(0))

# #6379
static:
  import algorithm

  var numArray = [1, 2, 3, 4, -1]
  numArray.sort(cmp)
  assert numArray == [-1, 1, 2, 3, 4]

  var str = "cba"
  str.sort(cmp)
  assert str == "abc"

# #6086
import math, sequtils, future

block:
  proc f: int =
    toSeq(10..<10_000).filter(
      a => a == ($a).map(
        d => (d.ord-'0'.ord).int^4
      ).sum
    ).sum

  var a = f()
  const b = f()

  assert a == b

block:
  proc f(): seq[char] =
    result = "hello".map(proc(x: char): char = x)

  var runTime = f()
  const compTime = f()
  assert runTime == compTime

# #6083
block:
  proc abc(): seq[int] =
    result = @[0]
    result.setLen(2)
    var tmp: int

    for i in 0 ..< 2:
      inc tmp
      result[i] = tmp

  const fact1000 = abc()
  assert fact1000 == @[1, 2]

# Tests for VM ops
block:
  static:
    assert "vm" in getProjectPath()

    let b = getEnv("UNSETENVVAR")
    assert b == ""
    assert existsEnv("UNSERENVVAR") == false
    putEnv("UNSETENVVAR", "VALUE")
    assert getEnv("UNSETENVVAR") == "VALUE"
    assert existsEnv("UNSETENVVAR") == true

    assert fileExists("MISSINGFILE") == false
    assert dirExists("MISSINGDIR") == false

# #7210
block:
  static:
    proc f(size: int): int =
      var some = newStringOfCap(size)
      result = size
    doAssert f(4) == 4