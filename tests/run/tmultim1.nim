discard """
  file: "tmultim1.nim"
  output: "7"
"""
# Test multi methods

type
  Expression = ref object {.inheritable.}
  Literal = ref object of Expression
    x: int
  PlusExpr = ref object of Expression
    a, b: Expression
    
method eval(e: Expression): int = quit "to override!"
method eval(e: Literal): int = return e.x
method eval(e: PlusExpr): int = return eval(e.a) + eval(e.b)

proc newLit(x: int): Literal =
  new(result)
  result.x = x
  
proc newPlus(a, b: Expression): PlusExpr =
  new(result)
  result.a = a
  result.b = b

echo eval(newPlus(newPlus(newLit(1), newLit(2)), newLit(4))) #OUT 7


