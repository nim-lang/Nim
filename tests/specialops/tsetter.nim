block: # ensure RHS of setter statement is treated as call operand
  proc `b=`(a: var int, c: proc (x: int): int) =
    a = c(a)

  proc foo(x: int): int = x + 1
  proc foo(x: float): float = x - 1

  var a = 123
  a.b = foo
  doAssert a == 124
