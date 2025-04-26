discard """
action: run
"""

#24913
block: 
  type
    A = object
      b: int
    B = object
      b: proc(x: float): int

  proc b(T: typedesc[A]; s: float): int = 5
  proc b(T: typedesc[B]; s: float): int = 7
  proc testme(x: float): int = 3
  doAssert A.b(1.0) == 5
  doAssert B.b(1.0) == 7
  doAssert B(b: testme).b(1.0) == 3

block:
  type
    Proc[T] = proc(text: T): int {.closure.}
    
    Rule[T] = object
      p: Proc[T]

  proc p(x: Rule[int]; y: float): int = 5
  proc sp(y: int): int = 3

  proc spring[T](rule: Rule[T]) =
    let p = proc (text: T) =
      doAssert rule.p(text) == 3
    p(default(T))

  Rule[int](p: sp).spring()

block:
  type
    Cont[T] = ref RootObj
    Rule[T] = object
      p: Cont[T]

  proc p(x: Rule[int]; y: int): int = 5

  proc spring[T](rule: Rule[T]) =
    let p = proc (x: T) =
      doAssert rule.p(x) == 5
    p(default(T))

  Rule[int]().spring()
