discard """
output: '''
10
20
int
20
3
x as ParameterizedType[T]
x as ParameterizedType[T]
x as ParameterizedType[T]
x as ParameterizedType
x as ParameterizedType
x as CustomTypeClass
1
2
3
4
5
6
a
b
t
e
s
t
z
e
1
2
3
20
10
5
'''
"""


import typetraits, strutils


block tcomparable:
  type
    Comparable = concept a
      (a < a) is bool

  proc myMax(a, b: Comparable): Comparable =
    if a < b:
      return b
    else:
      return a

  doAssert myMax(5, 10) == 10
  doAssert myMax(31.3, 1.23124) == 31.3



block tconceptinclosure:
  type
    FonConcept = concept x
      x.x is int
    GenericConcept[T] = concept x
      x.x is T
      const L = T.name.len
    Implementation = object
      x: int
    Closure = object
      f: proc()

  proc f1(x: FonConcept): Closure =
    result.f = proc () =
      echo x.x

  proc f2(x: GenericConcept): Closure =
    result.f = proc () =
      echo x.x
      echo GenericConcept.T.name

  proc f3[T](x: GenericConcept[T]): Closure =
    result.f = proc () =
      echo x.x
      echo x.L

  let x = Implementation(x: 10)
  let y = Implementation(x: 20)

  let a = x.f1
  let b = x.f2
  let c = x.f1
  let d = y.f2
  let e = y.f3

  a.f()
  d.f()
  e.f()



block overload_precedence:
  type ParameterizedType[T] = object

  type CustomTypeClass = concept c
    true

  # 3 competing procs
  proc a[T](x: ParameterizedType[T]) =
    echo "x as ParameterizedType[T]"

  proc a(x: ParameterizedType) =
    echo "x as ParameterizedType"

  proc a(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  # the same procs in different order
  proc b(x: ParameterizedType) =
    echo "x as ParameterizedType"

  proc b(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  proc b[T](x: ParameterizedType[T]) =
    echo "x as ParameterizedType[T]"

  # and yet another order
  proc c(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  proc c(x: ParameterizedType) =
    echo "x as ParameterizedType"

  proc c[T](x: ParameterizedType[T]) =
    echo "x as ParameterizedType[T]"

  # remove the most specific one
  proc d(x: ParameterizedType) =
    echo "x as ParameterizedType"

  proc d(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  # then shuffle the order again
  proc e(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  proc e(x: ParameterizedType) =
    echo "x as ParameterizedType"

  # the least specific one is a match
  proc f(x: CustomTypeClass) =
    echo "x as CustomTypeClass"

  a(ParameterizedType[int]())
  b(ParameterizedType[int]())
  c(ParameterizedType[int]())
  d(ParameterizedType[int]())
  e(ParameterizedType[int]())
  f(ParameterizedType[int]())



block templates:
  template typeLen(x): int = x.type.name.len

  template bunchOfChecks(x) =
    x.typeLen > 3
    x != 10 is bool

  template stmtListExprTmpl(x: untyped): untyped =
    x is int
    x

  type
    Obj = object
      x: int

    Gen[T] = object
      x: T

    Eq = concept x, y
      (x == y) is bool

    NotEq = concept x, y
      (x != y) is bool

    ConceptUsingTemplate1 = concept x
      echo x
      sizeof(x) is int
      bunchOfChecks x

    ConceptUsingTemplate2 = concept x
      stmtListExprTmpl x

  template ok(x) =
    static: assert(x)

  template no(x) =
    static: assert(not(x))

  ok int is Eq
  ok int is NotEq
  ok string is Eq
  ok string is NotEq
  ok Obj is Eq
  ok Obj is NotEq
  ok Gen[string] is Eq
  ok Gen[int] is NotEq

  no int is ConceptUsingTemplate1
  ok float is ConceptUsingTemplate1
  no string is ConceptUsingTemplate1

  ok int is ConceptUsingTemplate2
  no float is ConceptUsingTemplate2
  no string is ConceptUsingTemplate2



block titerable:
  type
    Iterable[T] = concept x
      for value in x:
        type(value) is T

  proc sum[T](iter: Iterable[T]): T =
    static: echo T.name
    for element in iter:
      static: echo element.type.name
      result += element

  doAssert sum([1, 2, 3, 4, 5]) == 15



block tmanual:
  template accept(e) =
    static: assert compiles(e)

  template reject(e) =
    static: assert(not compiles(e))

  type
    Container[T] = concept c
      c.len is Ordinal
      items(c) is T
      for value in c:
        type(value) is T

  proc takesIntContainer(c: Container[int]) =
    for e in c: echo e

  takesIntContainer(@[1, 2, 3])
  reject takesIntContainer(@["x", "y"])

  proc takesContainer(c: Container) =
    for e in c: echo e

  takesContainer(@[4, 5, 6])
  takesContainer(@["a", "b"])
  takesContainer "test"
  reject takesContainer(10)



block modifiers_in_place:
  type
    VarContainer[T] = concept c
      put(var c, T)
    AltVarContainer[T] = concept var c
      put(c, T)
    NonVarContainer[T] = concept c
      put(c, T)
    GoodContainer = object
      x: int
    BadContainer = object
      x: int

  proc put(x: BadContainer, y: int) = discard
  proc put(x: var GoodContainer, y: int) = discard

  template ok(x) = assert(x)
  template no(x) = assert(not(x))

  static:
    ok GoodContainer is VarContainer[int]
    ok GoodContainer is AltVarContainer[int]
    no BadContainer is VarContainer[int]
    no BadContainer is AltVarContainer[int]
    ok GoodContainer is NonVarContainer[int]
    ok BadContainer is NonVarContainer[int]



block treversable:
  type
    Reversable[T] = concept a
      a[int] is T
      a.high is int
      a.len is int
      a.low is int

  proc get[T](s: Reversable[T], n: int): T =
    s[n]

  proc hi[T](s: Reversable[T]): int =
    s.high

  proc lo[T](s: Reversable[T]): int =
    s.low

  iterator reverse[T](s: Reversable[T]): T =
    assert hi(s) - lo(s) == len(s) - 1
    for z in hi(s).countdown(lo(s)):
      yield s.get(z)

  for s in @["e", "z"].reverse:
    echo s



block tmonoid:
  type Monoid = concept x, y
    x + y is type(x)
    type(z(type(x))) is type(x)

  proc z(x: typedesc[int]): int = 0

  doAssert(int is Monoid)

  # https://github.com/nim-lang/Nim/issues/8126
  type AdditiveMonoid = concept x, y, type T
    x + y is T

    # some redundant checks to test an alternative approaches:
    type TT = type(x)
    x + y is type(x)
    x + y is TT

  doAssert(1 is AdditiveMonoid)



block tesqofconcept:
  type
    MyConcept = concept x
      someProc(x)
    SomeSeq = seq[MyConcept]

  proc someProc(x:int) = echo x

  proc work (s: SomeSeq) =
    for item in s:
      someProc item

  var s = @[1, 2, 3]
  work s



block tvectorspace:
  type VectorSpace[K] = concept x, y
    x + y is type(x)
    zero(type(x)) is type(x)
    -x is type(x)
    x - y is type(x)
    var k: K
    k * x is type(x)

  proc zero(T: typedesc): T = 0

  static:
    assert float is VectorSpace[float]
    # assert float is VectorSpace[int]
    # assert int is VectorSpace



block tstack:
  template reject(e) =
    static: assert(not compiles(e))

  type
    ArrayStack = object
      data: seq[int]

  proc push(s: var ArrayStack, item: int) =
    s.data.add item

  proc pop(s: var ArrayStack): int =
    return s.data.pop()

  type
    Stack[T] = concept var s
      s.push(T)
      s.pop() is T

      type ValueType = T
      const ValueTypeName = T.name.toUpperAscii

  proc genericAlgorithm[T](s: var Stack[T], y: T) =
    static:
      echo "INFERRED ", T.name
      echo "VALUE TYPE ", s.ValueType.name
      echo "VALUE TYPE NAME ", s.ValueTypeName

    s.push(y)
    echo s.pop

  proc implicitGeneric(s: var Stack): auto =
    static:
      echo "IMPLICIT INFERRED ", s.T.name, " ", Stack.T.name
      echo "IMPLICIT VALUE TYPE ", s.ValueType.name, " ", Stack.ValueType.name
      echo "IMPLICIT VALUE TYPE NAME ", s.ValueTypeName, " ", Stack.ValueTypeName

    return s.pop()

  var s = ArrayStack(data: @[])

  s.push 10
  s.genericAlgorithm 20
  echo s.implicitGeneric

  reject s.genericAlgorithm "x"
  reject s.genericAlgorithm 1.0
  reject "str".implicitGeneric
  reject implicitGeneric(10)



import libs/[trie_database, trie]
block ttrie:
  proc takeDb(d: TrieDatabase) = discard
  var mdb: MemDB
  takeDb(mdb)



import mvarconcept
block tvar:
  # bug #2346, bug #2404
  echo randomInt(5)
