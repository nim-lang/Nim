# This test is included from within tunittests
import unittest

test "loop variables are captured by ref":
  var funcs: seq[proc (): int {.closure.}] = @[]

  for i in 0..10:
    let ii = i
    funcs.add do -> int: return ii * ii

  check funcs[0]() == 100
  check funcs[3]() == 100

test "loop variables in closureScope are captured by copy":
  var funcs: seq[proc (): int {.closure.}] = @[]

  for i in 0..10:
    closureScope:
      let ii = i
      funcs.add do -> int: return ii * ii

  check funcs[0]() == 0
  check funcs[3]() == 9
