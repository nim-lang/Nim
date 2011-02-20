discard """
  file: "tmultim1.nim"
  output: "7"
"""
# Test multi methods

type
  TExpr = object
  TLiteral = object of TExpr
    x: int
  TPlusExpr = object of TExpr
    a, b: ref TExpr
    
method eval(e: ref TExpr): int = quit "to override!"
method eval(e: ref TLiteral): int = return e.x
method eval(e: ref TPlusExpr): int = return eval(e.a) + eval(e.b)

proc newLit(x: int): ref TLiteral =
  new(result)
  result.x = x
  
proc newPlus(a, b: ref TExpr): ref TPlusExpr =
  new(result)
  result.a = a
  result.b = b

echo eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4))) #OUT 7


