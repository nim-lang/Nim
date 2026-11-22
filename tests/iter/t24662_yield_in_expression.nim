discard """
  targets: "c cpp js"
  output: '''
callArg
eval a=1
got 1
eval b=102
eval c=103
show3 1 102 103
nested
eval a=1
got 1
eval b=102
got 2
eval c=203
eval d=204
114234
andOr
got 1
got 2
r1 false
got 3
got 5
r3 true
got 7
a false
ifExpr 1
eval pre=1
got 10
eval in=102
ifExpr 1 -> 103
ifExpr -1
eval pre=1
got 20
ifExpr -1 -> -2
ifExpr 0
eval pre=1
got 30
ifExpr 0 -> 1
caseExpr 1
got 1
got 2
one
caseExpr 2
got 1
two
caseExpr 3
got 1
got 3
many
tryExpr 5
got 1
fin
tryExpr 5 -> 20
tryExpr 0
got 1
got 2
fin
tryExpr 0 -> -1
pragmaBlock
got 1
pragmaBlock 5
blockExpr
got 1
blockExpr 9
'''
"""

# Refs #24662. A `yield` inside an expression makes lowerStmtListExprs hoist the
# operands into temporaries; each form below needs one to keep a value that was
# computed before the `yield`.

var counter = 0

proc tick(name: string): int =
  inc counter
  echo "eval ", name, "=", counter
  counter

proc show3(a, b, c: int) =
  echo "show3 ", a, " ", b, " ", c

proc sum3(a, b, c: int): int = a * 100 + b * 10 + c

proc risky(k: int): int =
  if k == 0:
    raise newException(ValueError, "zero")
  100 div k

# A template's body is a statement list, which is how a `yield` ends up inside an
# expression.
template yieldThen(v: int, e: untyped): untyped =
  yield v
  e

# The consumer changes `counter` between resumes, so an operand that is
# evaluated again after the `yield` instead of before it prints a different
# number or appears in a different place.
template drive(it: untyped) =
  counter = 0
  for y in it:
    echo "got ", y
    counter += 100

iterator callArg(): int {.closure.} =
  echo "callArg"
  show3(tick("a"), yieldThen(1, tick("b")), tick("c"))

iterator nested(): int {.closure.} =
  echo "nested"
  echo sum3(sum3(tick("a"), yieldThen(1, tick("b")), 0), yieldThen(2, tick("c")), tick("d"))

iterator andOr(): int {.closure.} =
  echo "andOr"
  let r1 = yieldThen(1, counter < 1000) and yieldThen(2, counter > 1000)
  echo "r1 ", r1
  let r2 = yieldThen(3, false) and yieldThen(4, true) # right side must not run
  doAssert not r2
  let r3 = yieldThen(5, true) or yieldThen(6, false) # right side must not run
  echo "r3 ", r3
  counter = 0
  # the left value is true when it is computed, the right one false after the resume
  let a = (counter < 50) and yieldThen(7, counter < 50)
  echo "a ", a

iterator ifExpr(k: int): int {.closure.} =
  echo "ifExpr ", k
  let v = tick("pre") + (if k > 0: yieldThen(10, tick("in")) elif k < 0: yieldThen(20, k * 3) else: yieldThen(30, 0))
  echo "ifExpr ", k, " -> ", v

iterator caseExpr(k: int): int {.closure.} =
  echo "caseExpr ", k
  let v = case yieldThen(1, k)
    of 1: yieldThen(2, "one")
    of 2: "two"
    else: yieldThen(3, "many")
  echo v

iterator tryExpr(k: int): int {.closure.} =
  echo "tryExpr ", k
  let v = try: yieldThen(1, risky(k))
    except ValueError: yieldThen(2, -1)
    finally: echo "fin"
  echo "tryExpr ", k, " -> ", v

iterator pragmaBlock(): int {.closure.} =
  echo "pragmaBlock"
  let v = block:
    {.cast(gcsafe).}:
      yieldThen(1, 5)
  echo "pragmaBlock ", v

iterator blockExpr(): int {.closure.} =
  echo "blockExpr"
  let v = block: yieldThen(1, 9)
  echo "blockExpr ", v

drive callArg()
drive nested()
drive andOr()
drive ifExpr(1)
drive ifExpr(-1)
drive ifExpr(0)
drive caseExpr(1)
drive caseExpr(2)
drive caseExpr(3)
drive tryExpr(5)
drive tryExpr(0)
drive pragmaBlock()
drive blockExpr()
