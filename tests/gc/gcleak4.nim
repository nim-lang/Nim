discard """
  outputsub: "no leak: "
"""

when defined(GC_setMaxPause):
  GC_setMaxPause 2_000

type
  TExpr = object ## abstract base class for an expression
  PLiteral = ref TLiteral
  TLiteral = object of TExpr
    x: int
  TPlusExpr = object of TExpr
    a, b: ref TExpr
    
method eval(e: ref TExpr): int =
  # override this base method
  quit "to override!"

method eval(e: ref TLiteral): int = return e.x

method eval(e: ref TPlusExpr): int =
  # watch out: relies on dynamic binding
  return eval(e.a) + eval(e.b)

proc newLit(x: int): ref TLiteral =
  new(result)
  {.watchpoint: result.}
  result.x = x
  
proc newPlus(a, b: ref TExpr): ref TPlusExpr =
  new(result)
  {.watchpoint: result.}
  result.a = a
  result.b = b

for i in 0..100_000:
  if eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4))) != 7:
    quit "error: wrong result"
  if getOccupiedMem() > 3000_000: quit("still a leak!")

echo "no leak: ", getOccupiedMem()
