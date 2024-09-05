# Cases that used to only work due to weird workarounds in the compiler
# involving not instantiating calls in generic bodies which are removed
# due to breaking statics.
# The issue was that these calls are compiled as regular expressions at
# the generic declaration with unresolved generic parameter types,
# which are special cased in some places in the compiler, but sometimes
# treated like real types.

block:
  type Base10 = object

  func maxLen(T: typedesc[Base10], I: type): int8 =
    when I is uint8:
      3
    elif I is uint16:
      5
    elif I is uint32:
      10
    elif I is uint64:
      20
    else:
      when sizeof(uint) == 4:
        10
      else:
        20
  
  type
    Base10Buf[T: SomeUnsignedInt] = object
      data: array[maxLen(Base10, T), byte]
      len: int8

  var x: Base10Buf[uint32]
  doAssert x.data.len == 10
  var y: Base10Buf[uint16]
  doAssert y.data.len == 5

import typetraits

block thardcases:
  proc typeNameLen(x: typedesc): int {.compileTime.} =
    result = x.name.len
  macro selectType(a, b: typedesc): typedesc =
    result = a

  type
    Foo[T] = object
      data1: array[T.high, int]
      data2: array[typeNameLen(T), float]
      data3: array[0..T.typeNameLen, selectType(float, int)]
  
  type MyEnum = enum A, B, C, D

  var f1: Foo[MyEnum]
  var f2: Foo[int8]

  doAssert high(f1.data1) == 2 # (D = 3) - 1 == 2
  doAssert high(f1.data2) == 5 # (MyEnum.len = 6) - 1 == 5

  doAssert high(f2.data1) == 126 # 127 - 1 == 126
  doAssert high(f2.data2) == 3 # int8.len - 1 == 3

  static:
    doAssert high(f1.data1) == ord(C)
    doAssert high(f1.data2) == 5 # length of MyEnum minus one, because we used T.high

    doAssert high(f2.data1) == 126
    doAssert high(f2.data2) == 3

    doAssert high(f1.data3) == 6 # length of MyEnum
    doAssert high(f2.data3) == 4 # length of int8

    doAssert f2.data3[0] is float

import muninstantiatedgenericcalls

block:
  var x: Leb128Buf[uint32]
  doAssert x.data.len == 5
  var y: Leb128Buf[uint16]
  doAssert y.data.len == 3

import macros

block: # issue #12415
  macro isSomePointerImpl(t: typedesc): bool =
    var impl = t.getTypeInst[1].getTypeImpl
    if impl.kind == nnkDistinctTy:
      impl = impl[0].getTypeImpl
    if impl.kind in {nnkPtrTy,nnkRefTy}:
      result = newLit(true)
    elif impl.kind == nnkSym and impl.eqIdent("pointer"):
      result = newLit(true)
    else:
      result = newLit(false)

  proc isSomePointer[T](t: typedesc[T]): bool {.compileTime.} =
    isSomePointerImpl(t)

  type
    Option[T] = object
      ## An optional type that stores its value and state separately in a boolean.
      when isSomePointer(typedesc(T)):
        val: T
      else:
        val: T
        has: bool
  var x: Option[ref int]
  doAssert not compiles(x.has)
  var y: Option[int]
  doAssert compiles(y.has)

block: # issue #2002
  proc isNillable(T: typedesc): bool =
    when compiles((let v: T = nil)):
      return true
    else:
      return false

  type
    Foo[T] = object
      when isNillable(T):
        nillable: float
      else:
        notnillable: int

  var val1: Foo[ref int]
  doAssert compiles(val1.nillable)
  doAssert not compiles(val1.notnillable)
  var val2: Foo[int]
  doAssert not compiles(val2.nillable)
  doAssert compiles(val2.notnillable)

block: # issue #1771
  type
    Foo[X, T] = object
      bar: array[X.low..X.high, T]

  proc test[X, T](f: Foo[X, T]): T =
    f.bar[X.low]

  var a: Foo[range[0..2], float]
  doAssert test(a) == 0.0

block: # issue #23730
  proc test(M: static[int]): array[1 shl M, int] = discard
  doAssert len(test(3)) == 8
  doAssert len(test(5)) == 32

block: # issue #19819
  type
    Example[N: static int] = distinct int
    What[E: Example] = Example[E.N + E.N]

block: # issue #23339
  type
    A = object
    B = object
  template aToB(t: typedesc[A]): typedesc = B
  type
    Inner[I] = object
      innerField: I
    Outer[O] = object
      outerField: Inner[O.aToB]
  var x: Outer[A]
  doAssert typeof(x.outerField.innerField) is B

block: # deref syntax
  type
    Enqueueable = concept x
      x is ptr
    Foo[T: Enqueueable] = object
      x: typeof(default(T)[])

  proc p[T](f: Foo[T]) =
    var bar: Foo[T]
    discard
  var foo: Foo[ptr int]
  p(foo)
  doAssert foo.x is int
  foo.x = 123
  doAssert foo.x == 123
  inc foo.x
  doAssert foo.x == 124

block:
  type Generic[T] = object
    field: T
  macro foo(x: typed): untyped = x
  macro bar[T](x: typedesc[Generic[T]]): untyped = x
  type
    Foo[T] = object
      field: Generic[int].foo()
    Foo2[T] = object
      field: Generic[T].foo()
    Bar[T] = object
      field: Generic[int].bar()
    Bar2[T] = object
      field: Generic[T].bar()
  var x: Foo[int]
  var x2: Foo2[int]
  var y: Bar[int]
  var y2: Bar2[int]

block:
  macro pick(x: static int): untyped =
    if x < 100:
      result = bindSym"int"
    else:
      result = bindSym"float"
  
  type Foo[T: static int] = object
    fixed1: pick(25)
    fixed2: pick(125)
    unknown: pick(T)
  
  var a: Foo[123]
  doAssert a.fixed1 is int
  doAssert a.fixed2 is float
  doAssert a.unknown is float
  var b: Foo[23]
  doAssert b.fixed1 is int
  doAssert b.fixed2 is float
  doAssert b.unknown is int

import std/sequtils

block: # version of #23432 with `typed`, don't delay instantiation
  type
    Future[T] = object
    InternalRaisesFuture[T, E] = object
  macro Raising[T](F: typedesc[Future[T]], E: varargs[typed]): untyped =
    let raises = nnkTupleConstr.newTree(E.mapIt(it))
    nnkBracketExpr.newTree(
      ident "InternalRaisesFuture",
      nnkDotExpr.newTree(F, ident"T"),
      raises
    )
  type X[E] = Future[void].Raising(E)
  proc f(x: X) = discard
  var v: Future[void].Raising([ValueError])
  f(v)

block: # issue #22647
  proc c0(n: static int): int = 8
  proc c1(n: static int): int = n div 2
  proc c2(n: static int): int = n * 2
  proc c3(n: static int, n2: int): int = n * n2
  proc `**`(n: static int, n2: int): int = n * n2
  proc c4(n: int, n2: int): int = n * n2

  type
    a[N: static int] = object
      f0 : array[N, int]

    b[N: static int] = object
      f0 : a[c0(N)]  # does not work
      f1 : a[c1(N)]  # does not work
      f2 : a[c2(N)]  # does not work
      f3 : a[N * 2]  # does not work
      f4 : a[N]      # works
      f5: a[c3(N, 2)]
      f6: a[N ** 2]
      f7: a[2 * N]
      f8: a[c4(N, 2)]

  proc p[N: static int](x : a[N]) = discard x.f0[0]
  template check(x, s: untyped) =
    p(x)
    doAssert x is a[s]
    doAssert x.N == s
    doAssert typeof(x).N == s
    doAssert x.f0 == default(array[s, int])
    doAssert x.f0.len == s
    proc p2[N: static int](y : a[N]) {.gensym.} =
      doAssert y is a[s]
      doAssert y.N == s
      doAssert typeof(y).N == s
      doAssert y.f0 == default(array[s, int])
      doAssert y.f0.len == s
    p2(x)
    proc p3(z: typeof(x)) {.gensym.} = discard
    p3(default(a[s]))
  proc p[N: static int](x : b[N]) =
    x.f0.check(8)
    x.f1.check(2)
    x.f2.check(8)
    x.f3.check(8)
    x.f4.check(4)
    x.f5.check(8)
    x.f6.check(8)
    x.f7.check(8)
    x.f8.check(8)

  var x: b[4]
  x.p()

block: # issue #1969
  type ZeroGenerator = object
  proc next(g: ZeroGenerator): int = 0
  # This compiles.
  type TripleOfInts = tuple
    a, b, c: typeof(new(ZeroGenerator)[].next)
  # This raises a compiler error before it's even instantiated.
  # The `new` proc can't be resolved because `Generator` is not defined.
  type TripleLike[Generator] = tuple
    a, b, c: typeof(new(Generator)[].next)

import std/atomics

block: # issue #12720
  const CacheLineSize = 128
  type
    Enqueueable = concept x, type T
      x is ptr
      x.next is Atomic[pointer]
    MyChannel[T: Enqueueable] = object
      pad: array[CacheLineSize - sizeof(default(T)[]), byte]
      dummy: typeof(default(T)[])

block: # issue #12714
  type
    Enqueueable = concept x, type T
      x is ptr
      x.next is Atomic[pointer]
    MyChannel[T: Enqueueable] = object
      dummy: type(default(T)[])

block: # issue #24044
  type ArrayBuf[N: static int, T = byte] = object
    buf: array[N, T]
  template maxLen(T: type): int =
    sizeof(T) * 2
  type MyBuf[I] = ArrayBuf[maxLen(I)]
  var v: MyBuf[int]

block: # issue #15959
  proc byLent2[T](a: T): lent type(a[0]) = a[0] # Error: type mismatch: got <T, int literal(0)>
  proc byLent3[T](a: T): lent typeof(a[0]) = a[0] # ditto
  proc byLent4[T](a: T): lent[type(a[0])] = a[0] # Error: no generic parameters allowed for lent
  var x = @[1, 2, 3]
  doAssert byLent2(x) == 1
  doAssert byLent2(x) is lent int
  doAssert byLent3(x) == 1
  doAssert byLent3(x) is lent int
  doAssert byLent4(x) == 1
  doAssert byLent4(x) is lent int

block: # issue #22342, type section version of #22607
  type GenAlias[isInt: static bool] = (
    when isInt:
      int
    else:
      float
  )
  doAssert GenAlias[true] is int
  doAssert GenAlias[false] is float
  proc foo(T: static bool): GenAlias[T] = discard
  doAssert foo(true) is int
  doAssert foo(false) is float
  proc foo[T: static bool](v: var GenAlias[T]) =
    v += 1
  var x: int
  foo[true](x)
  doAssert not compiles(foo[false](x))
  foo[true](x)
  doAssert x == 2
  var y: float
  foo[false](y)
  doAssert not compiles(foo[true](y))
  foo[false](y)
  doAssert y == 2

block: # `when`, test no constant semchecks
  type Foo[T] = (
    when false:
      {.error: "bad".}
    elif defined(neverDefined):
      {.error: "bad 2".}
    else:
      T
  )
  var x: Foo[int]
  type Bar[T] = (
    when true:
      T
    elif defined(js):
      {.error: "bad".}
    else:
      {.error: "bad 2".}
  )
  var y: Bar[int]
