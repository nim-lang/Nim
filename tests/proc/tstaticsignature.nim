when false: # issue #22607, needs proper nkWhenStmt handling
  proc test[x: static bool](
    t: (
      when x:
        int
      else:
        float
      )
  ) = discard
  test[true](1.int)
  test[false](1.0)
  doAssert not compiles(test[])

block: # expanded version of t8545
  template bar(a: static[bool]): untyped =
    when a:
      int
    else:
      float

  proc main() =
    proc foo1(a: static[bool]): auto = 1
    doAssert foo1(true) == 1

    proc foo2(a: static[bool]): bar(a) = 1
    doAssert foo2(true) == 1
    doAssert foo2(true) is int
    doAssert foo2(false) == 1.0
    doAssert foo2(false) is float

    proc foo3(a: static[bool]): bar(cast[bool](a)) = 1
    doAssert foo3(true) == 1
    doAssert foo3(true) is int
    doAssert foo3(false) == 1.0
    doAssert foo3(false) is float

    proc foo4(a: static[bool]): bar(static(a)) = 1
    doAssert foo4(true) == 1
    doAssert foo4(true) is int
    doAssert foo4(false) == 1.0
    doAssert foo4(false) is float

  static: main()
  main()

block: # issue #8406
  macro f(x: static[int]): untyped = discard
  proc g[X: static[int]](v: f(X)) = discard

import macros

block: # issue #8551
  macro distinctBase2(T: typedesc): untyped =
    let typeNode = getTypeImpl(T)
    expectKind(typeNode, nnkBracketExpr)
    if typeNode[0].typeKind != ntyTypeDesc:
      error "expected typeDesc, got " & $typeNode[0]
    var typeSym = typeNode[1]

    typeSym = getTypeImpl(typeSym)

    if typeSym.typeKind != ntyDistinct:
      error "type is not distinct: " & $typeSym.typeKind

    typeSym = typeSym[0]
    typeSym

  func distinctBase[T](a: T): distinctBase2(T) = distinctBase2(T)(a)

  type T = distinct int
  doAssert distinctBase(T(0)) is int
