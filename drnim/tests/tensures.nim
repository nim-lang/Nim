discard """
  nimout: '''tensures.nim(14, 10) Warning: BEGIN [User]
tensures.nim(23, 5) Warning: cannot prove:
0 < n [IndexCheck]
tensures.nim(63, 17) Warning: cannot prove: a < 4; counter example: y -> 2
a`1 -> 4
a -> 2
tensures.nim(67, 10) Warning: END [User]'''
  cmd: "drnim $file"
  action: "compile"
"""
import std/logic
{.push staticBoundChecks: defined(nimDrNim).}
{.warning: "BEGIN".}

proc fac(n: int) {.requires: n > 0.} =
  discard

proc g(): int {.ensures: result > 0.} =
  result = 10

fac 7 # fine
fac -45 # wrong

fac g() # fine

proc main =
  var x = g()
  fac x

main()

proc myinc(x: var int) {.ensures: x == old(x)+1.} =
  inc x
  {.assume: old(x)+1 == x.}

proc mainB(y: int) =
  var a = y
  if a < 3:
    myinc a
    {.assert: a < 4.}

mainB(3)

proc a(yy, z: int) {.requires: (yy - z) > 6.} = discard
# 'requires' must be weaker (or equal)
# 'ensures'  must be stronger (or equal)

# a 'is weaker than' b iff  b -> a
# a 'is stronger than' b iff a -> b
# --> We can use Z3 to compute whether 'var x: T = q' is valid

type
  F = proc (yy, z3: int) {.requires: z3 < 5 and z3 > -5 and yy > 10.}

var
  x: F = a # valid?

proc testAsgn(y: int) =
  var a = y
  if a < 3:
    a = a + 2
    {.assert: a < 4.}

testAsgn(3)

{.warning: "END".}
{.pop.}
