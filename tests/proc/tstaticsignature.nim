block: # issue #4228
  template seqType(t: typedesc): typedesc =
    when t is int:
      seq[int]
    else:
      seq[string]

  proc mkSeq[T: int|string](v: T): seqType(T) =
    result = newSeq[T](1)
    result[0] = v

  doAssert mkSeq("a") == @["a"]
  doAssert mkSeq(1) == @[1]

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

block:
  type Foo[T] = object
    x: T

  proc foo(x: Foo): Foo[x.T] =
    doAssert typeof(result) is typeof(x)

  var a: Foo[int]
  let b: Foo[int] = foo(a)
  doAssert b.x is int

block:
  type Foo[T: static int] = object
    x: array[T, int]
  
  proc double(x: int): int = x * 2

  proc foo[T: static int](x: Foo[T]): Foo[T.double] =
    doAssert typeof(result).T == double(typeof(x).T)

  var a: Foo[3]
  let b: Foo[6] = foo(a)
  doAssert $typeof(foo(a)) == "Foo[6]"

block:
  type Foo[T: static int] = object
    x: array[T, int]

  proc foo(x: Foo): Foo[x.T] =
    doAssert typeof(result).T == typeof(x).T
    doAssert typeof(result) is typeof(x)

  var a: Foo[3]
  let b: Foo[3] = foo(a)
  doAssert $typeof(foo(a)) == "Foo[3]"

block: # issue #7006
  type
    Node[T] = object
      val: T
      next: ref Node[T]
    HHSet[T, Key] = object
      data: seq[Node[T]]
  proc rawGet(hhs:HHSet; key: hhs.Key): ptr Node[hhs.T] =
    return nil # body doesn't matter
  var hhs: HHSet[string, cstring]
  discard hhs.rawGet("hello".cstring)

block: # issue #7008
  type Node[T] = object
    val: T
  # Compiles fine
  proc concreteProc(s: Node[cstring]; key: s.T) = discard
  # Also fine
  proc implicitGenericProc1(s: Node; key: s.T) = discard
  # still fine
  proc explicitGenericProc1[T](s: Node[T]; key: T) = discard
  # Internal Compiler Error!
  proc explicitGenericProc2[T](s: Node[T]; key: s.T) = discard
  let n = Node[int](val: 5)
  implicitGenericProc1(n, 5) # works
  explicitGenericProc1(n, 5) # works
  explicitGenericProc2(n, 5) # doesn't

block: # issue #20027
  block:
    type Test[T] = object
    proc run(self: Test): self.T = discard
    discard run(Test[int]())
  block:
    type Test[T] = object
    proc run[T](self: Test[T]): self.T = discard
    discard run(Test[int]())
  block:
    type Test[T] = object
    proc run(self: Test[auto]): self.T = discard
    discard run(Test[int]())

block: # issue #11112
  proc foo[A, B]: type(A.default + B.default) =
    discard
  doAssert foo[int, int]() is int

block: # tyStatic and tyFromExpr instantiation mid-match
  proc bar(x: int): int = x * 3
  proc bar2(x: static int): int = x * 4
  type Foo[T: static int] = distinct array[T, int]
  proc foo[T: static int](x: Foo[T], y: Foo[bar(T)]) = discard
  proc foo2[T: static int](x: Foo[T], y: Foo[bar2(T)]) = discard
  foo(Foo[1]([1]), Foo[3]([1, 2, 3]))
  foo2(Foo[1]([1]), Foo[4]([1, 2, 3, 4]))

block: # issue #4990
  type Foo[I: static[int], A: static[array[I, int]]] = object
    curIndex: int

  proc next[I: static[int], A: static[array[I, int]]](f: Foo[I, A]): string =
    discard
  const arr = [1, 2, 3]
  var f: Foo[arr.len, arr]
  discard next(f)

block: # issue #4990 comment
  type
    Foo[A: static[int], B: static[int], TokenType: enum, EofToken: static[TokenType]] = object
      curIndex: int
    MyEnum = enum
      meA, meB
    Bar = Foo[2, 3, MyEnum, meA]
  proc next[A: static[int], B: static[int], TokenType: enum,
            EofToken: static[TokenType]](f: Foo[A, B, TokenType, EofToken],
      a: static[(array[A, int], array[B, int])]): TokenType =
    TokenType(a[0][f.curIndex])
  const
    a = [1, 2]
    b = [3, 4, 5]
  template next(bar: Bar): MyEnum =
    next(Foo[2, 3, MyEnum, meA](bar), (a, b))
  let bar = Bar(curIndex: 0)
  doAssert bar.next() == meA

when false: # issue #22607, needs nkWhenStmt to be handled like nkRecWhen
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
