import std/lambdas

template identity1(x): untyped = x
template testAliasCompiles =
  const identity2 = alias2 identity1
  doAssert identity2(2) == identity1(2)

doAssert not compiles(testAliasCompiles())

{.push experimental:"alias".}

block:
  doAssert compiles(testAliasCompiles())
  testAliasCompiles()
  doAssert not compiles(identity2(2)) # alias is `gensym`, not `inject`

# test import of alias
from ./mlambda import mbar, elementType
const mbar2 = alias2 mbar

## templates with all optional params
template tfun(a = 1, b = 2): untyped = a*b
template tfunIdentical(a = 1, b = 2): untyped = a*b # different symbol with same content
template tfun2(): untyped = 12
template tfunDifferent(a = 5, b = 6): untyped = a + b

var count = 0

## routine with no return value
template tfun3() = count.inc

## test that works with overloads
proc funo(a: int): auto = $a
proc funo(a: string): auto = a

## test that works with generics
proc fung[T](a: T): auto = (a, a)

var icounter = 0
proc identity[T](a: T): T =
  ## to test side effects
  icounter.inc
  a

proc testAlias() =
  ## create alias in local scope
  const tfuna = alias2 tfun
  doAssert tfuna(3) == tfun(3)
  const tfun2a = alias2 tfun2
  doAssert tfun2a() == tfun2a()

  const tfunaBis = alias2 alias2 tfun # alias2(alias2(x)) is same as alias2(x)
  doAssert tfunaBis(3) == tfun(3)


  const tfun3a = alias2 tfun3
  count = 0
  tfun3a()
  doAssert count == 1
  block:
    # a local variable `count` doesn't hijack original one
    var count = 12
    tfun3a()
    doAssert count == 12
  doAssert count == 2

  ## with a proc (with side effects)
  proc tfun4() = count.inc
  const tfun4a = alias2 tfun4
  tfun4()
  doAssert count == 3

  doAssert type(tfun4a) is proc # usage indistinguishable from aliased symbol

  ## with an un-mapped variable count2
  template tfun5() =
    count2.inc

  block:
    var count2 = 12
    const tfun5a = alias2 tfun5
    const tfun5b = alias2 tfun5a # alias of alias
    tfun5a()
    doAssert count2 == 13
    tfun5b()
    doAssert count2 == 14

  block:
    const T = alias2 int # works with types
    const T2 = alias2 system.int # works with fully qualified
    const system2 = alias2 system # works with fully qualified
    const T3 = alias2 system2.int
    doAssert T is int
    doAssert T2 is int
    doAssert T3 is int

  block:
    doAssert mbar(5, alias2 tfun) == ("mbar", 5, tfun(5))
    doAssert mbar2(5, alias2 tfun) == ("mbar", 5, tfun(5))

proc testAliasReturn() =
  proc genAlias(x: static int): aliassym =
    when x == 1: result = alias2 tfun
    elif x == 2: alias2 tfunDifferent
    elif x == 3: result = alias2 tfun2
    else:
      static: doAssert false

  const y1 = alias2 genAlias(1)
  const y2 = alias2 genAlias(2)
  doAssert y1(4) == tfun(4)
  doAssert y2(4) == tfunDifferent(4)
  doAssert y1(4) != y2(4) # sanity check
  const z = alias2 tfun2
  doAssert z() == tfun2()
  const y3 = alias2 genAlias(3)
  doAssert y3() == tfun2()

proc testAliasTuple() =
  block:
    const funs = (alias2 tfun, alias2 tfun2)
    doAssert funs[0](3) == tfun(3)
    doAssert funs[1]() == tfun2()
  block:
    const funs = (a: alias2 tfun, b: alias2 tfun2)
    doAssert funs[0](3) == tfun(3)
    doAssert funs.a(3) == tfun(3)
    const funa = alias2 funs.a
    const funb = alias2 funs.b
    doAssert funa(3) == tfun(3)
    doAssert funb() == tfun2()

proc testAliasGeneric() =
  type A[Fun1: aliassym, Fun2] = object
    x: int
  proc initA(fun1: aliassym, fun2: aliassym, x: int): A[fun1,fun2] = typeof(result)(x: x)
  var a = initA(a~>a*10, a~>a*2, 7)
  doAssert a.Fun1(3) == 3*10
  doAssert a.Fun2(3) == 3*2

proc testAliasFields() =
  # this could be improved, by supporting:   `type B = object: fun1: aliassym fun2: aliassym`
  type A[T1, T2, T3] = object
    fun1: T1
    myconst: T2
  proc initA[T1, T2, T3](a1: T1, a2: T2, a3: T3): A[T1, T2, T3] =
    typeof(result)(fun1: alias2 a1, myconst: alias2 a2)
  const z = 123
  const a = initA(a~>a*10, alias2 z, (a,b)~>a*b)
  static: doAssert a.myconst == 123
  doAssert a.fun1(3) == 3*10
  doAssert a.T3(3,4) == 3*4

proc testStatic() =
  # aliassym can replace `static[T]`
  proc fn(a, b: aliassym, c: int): string =
    const a2 = a # sanity check to make sure it's static
    const b2 = b
    doAssert a is int
    doAssert b is seq[string]
    $(a, a2, b, b2, $type(a), $type(b), c)
  doAssert fn(lambdaStatic 12, lambdaStatic @["foo", "bar"], 13) == """(12, 12, @["foo", "bar"], @["foo", "bar"], "int", "seq[string]", 13)"""

proc testTypedesc() =
  # aliassym can replace `typedesc[T]`
  proc fn(t1, t2, t3: aliassym): string =
    var a1: t1
    doAssert a1 is float32
    doAssert t1 is float32
    doAssert float32 is t1
    var a2: t2
    doAssert t2 is uint8
    result = $($t1, t1.default, $t2, $t3)
  type Foo[T] = object
  doAssert fn(lambdaType float32, lambdaType type(1u8+2u8), lambdaType Foo[int]) == """("float32", 0.0, "uint8", "Foo[system.int]")"""

proc testLambdaIt() =
  const fun = lambdaIt (it, it)
  doAssert fun(3) == (3, 3)
  doAssert fun("foo") == ("foo", "foo")

  icounter = 0
  doAssert fun(identity("foo")) == ("foo", "foo")
  doAssert icounter == 1  # side effect safe
  block:
    template fun2(it): untyped = (it, it) # not side effect safe
    icounter = 0
    doAssert fun2(identity("foo")) == ("foo", "foo")
    doAssert icounter == 2 # side effect executed each time argument is used

proc testArrow() =
  block: # 1 arg
    const fun = a ~> (a, a)
    doAssert fun(3) == (3, 3)
    doAssert fun("foo") == ("foo", "foo")
    icounter = 0
    doAssert fun(identity("foo")) == ("foo", "foo")
    doAssert icounter == 1 # side effect safe

  block: # 2 args
    const fun = (a, b) ~> a*b
    doAssert fun(3, 4) == 3*4

  block: # 0 args
    const fun = () ~> 14
    doAssert fun() == 14
 
  block: # example with local capture
    var z = 0
    const fun = () ~> (z.inc; z*10)
    doAssert fun() == 10
    doAssert fun() == 20
    doAssert z == 2

  block: # void return
    var z = 0
    const fun = () ~> z.inc
    for i in 0..<3: fun()
    doAssert z == 3

  block: # passing a lambda to a proc
    proc mapSum[T, Fun](a: T, fun: Fun): auto =
      result = default elementType(a)
      for ai in a: result += fun(ai)
    doAssert mapSum(@[1,2,3], x~>x*10) == 10 + 20 + 30
    doAssert mapSum(@[1,2,3], lambdaIt it*10) == 10 + 20 + 30

    var it = 132 # not confused by this
    doAssert mapSum(@[1,2,3], lambdaIt it*10) == 10 + 20 + 30
    # doAssert mapSum(@[1,2,3], it*10) == 10 + 20 + 30
      # this would work (and should not)
      # it's one of the reasons why `~>` is often preferable
      # (that and fact that ~> can take any number of input arguments)

  block: # aliasing things like echo, assert
    const echo2 = alias2 echo
    doAssert compiles echo2()
    doAssert compiles echo2(1, 2)
    const myAssert = alias2 assert # BUG: `const myAssert = alias2 doAssert` gives ambiguity error (with const doAssert = doAssertImpl); maybe need to propagate scope more carefully?
    doAssertRaises(Exception): myAssert(1+1 == 3)
    const fun = () ~> (1,2)
    doAssert fun() == (1,2)
    macro bar(a = 7, b: untyped): untyped = a
    const bar2 = alias2 bar
    doAssert bar(a = 2, b = nonexistant) == 2
    doAssert bar(b = nonexistant) == 7

proc testArrowWrongSym() =
  iterator myIter[T2](fun: T2): auto =
    yield fun(3)
  template x(a: int): untyped = discard
    # `x` is a distractor symbol that turns `x` into a symbol inside `bar`
  template bar(): untyped = myIter(x~>x*10)
  proc first[T](a: T): auto =
    for ai in a(): return ai
  doAssert first(alias2 bar) == 3*10

var countCT {.compileTime.} = 0

proc testProc() =
  ## pass alias to proc
  block:
    proc bar[T](a: T, fun: aliassym): auto = fun(a) # passing to a generic
    doAssert bar(10, alias2 tfun) == tfun(10)
    doAssert bar(10, alias2 funo) == funo(10) # passing overload works
    doAssert bar("foo", alias2 funo) == funo("foo")
    doAssert bar("foo", alias2 fung) == fung("foo") # passing generic works

  block:
    proc bar[T, Fun](a: T, fun: Fun): auto = fun(a) # passing aliassym as a generic T
    doAssert bar(10, alias2 tfun) == tfun(10)
    doAssert bar(10, alias2 funo) == funo(10)
    doAssert bar("foo", alias2 funo) == funo("foo")

  block:
    proc bar(a: int, fun: aliassym): auto = fun(a) # passing to a regular proc (implicitly generic)
    doAssert bar(10, alias2 tfun) == tfun(10)

  block:
    # multiple alias: unlike `seq`, aliassym is not bind-once
    proc bar(a: int, fun1, fun2: aliassym): auto = (fun1(a), fun2(a))
    template tfun2(a): untyped = a*3
    doAssert bar(10, alias2 tfun, alias2 tfun2) == (tfun(10), tfun2(10))

  block:
    # can use at CT
    proc bar(a: int, fun: aliassym): auto =
      const b = fun(18)
      (a,b)
    doAssert bar(10, alias2 tfun) == (10, tfun(18))

  block:
    proc bar(a: int, fun: aliassym): auto =
      const b = fun(18)
      (a,b)
    doAssert bar(10, alias2 tfun) == (10, tfun(18))

  block: # optional params
    proc bar(a: int, fun: aliassym = alias2 tfun): auto = fun(a)
    doAssert bar(10, alias2 tfun) == tfun(10)
    doAssert bar(10) == tfun(10)
    proc bar2(a: int, fun1: aliassym, fun2: aliassym = alias2 tfun): auto = (fun1(a), fun2(a))
    doAssert bar2(10, alias2 tfun, alias2 tfun) == (tfun(10), tfun(10))

  block: # optional params: void default works
    proc bar(a: int, fun: aliassym = alias2 void): auto =
      when fun is void: "def"
      else: fun(a)
    doAssert bar(10, alias2 tfun) == tfun(10)
    doAssert bar(10) == "def"

  block:
    # check correctness of `sameTypeAux` to make sure unique instantiations
    # are based on whether aliased symbols are identical
    proc bar(fun: aliassym) =
      static: countCT.inc
    proc bar2(fun: aliassym) =
      static: countCT+=10
    bar(alias2 tfun)
    bar(alias2 tfun) # should not re-instantiate
    bar(alias2 tfunIdentical) # should re-instantiate despite tfunIdentical being structurally identical
    bar2(alias2 funo)
    bar2(alias2 funo) # should re-instantiate (despite being overloaded)
    const countCT2 = countCT
    doAssert countCT2 == 1 + 1 + 10

  block:
    proc bar[T](a: T): auto =
      # make sure works inside generic and that `tfun2` doesn't get expanded too early
      const y1 = alias2 tfun2
      return y1()
    doAssert bar(12) == tfun2()

import std/macros

proc testMacro() =
  ## pass alias to macro
  block:
    macro bari(a: int, fun: typed): untyped =
      result = quote do:
        (`a`, `fun`(`a`))
    doAssert bari(11, alias2 tfun) == (11, tfun(11))

  block:
    macro bari(a: static int, fun: aliassym): untyped =
      newLit fun(a)
    doAssert bari(11, alias2 tfun) == 11*2

  block:
    macro bari(a: bool, fun: aliassym): untyped =
      let b = newLit fun(3)
      let c = repr(a)
      result = quote do:
        (`a`, `b`, `c`)
    doAssert bari(1+1 == 2, alias2 tfun) == (true, 6, "true")

  block: # pass macro to macro
    macro bar1(a: int): untyped = newLit repr(a)
    macro bar2(a: static int, b: int, fun: aliassym): untyped =
      let s = newLit fun(a * 3)
      result = quote do: (`s`, `b`)
    doAssert bar2(12, 3, alias2 bar1) == ("a * 3", 3)

proc testTemplate() =
  ## pass alias to template
  template bar1(fun: aliassym): untyped =
    ("testTemplate.1", fun(1), fun(2), fun())
  doAssert bar1(alias2 tfun) == ("testTemplate.1", 2, 4, 2)

  template bar2[T](fun: T): untyped =
    ("testTemplate.2", fun(1), fun(2))
  doAssert bar2(a~>a*10) == ("testTemplate.2", 10, 20)

proc test5702() = # fix https://github.com/nim-lang/Nim/issues/5702
  iterator zip[T1, T2](a: openarray[T1], b: openarray[T2]): (T1,T2) {.inline.} =
    let len = min(a.len, b.len)
    for i in 0..<len:
      yield (a[i], b[i])

  iterator zipWith[T1,T2,T3](f: T3, a: openarray[T1], b: openarray[T2]): auto {.inline.} =
    for i,j in zip(a,b):
      yield f(i,j)

  proc foo(args: varargs[int]): seq[(int, int)] =
    for i in zip(args, args):
      result.add i

  proc bar(args: varargs[int]): seq[int] =
    for i in zipWith(alias2 `+`, args, args):
      result.add i

  doAssert foo(1,2,3,4) == @[(1, 1), (2, 2), (3, 3), (4, 4)]
  doAssert bar(1,2,3,4) == @[2, 4, 6, 8]

proc test9679() = # closes https://github.com/nim-lang/Nim/issues/9679
  type
    Foo[T] = object
      bar*: int
      dummy: T

  proc initFoo(T: type, bar: int): Foo[T] =
    result.bar = 1

  proc fails[T](x: static Foo[T]) =
    const y = x.bar

  proc works[T](x: T) =
    const y = x.bar

  const foo = initFoo(int, 2)
  # fails(foo) # fails with static
  works(alias2 foo) # works with alias

proc testAll*() =
  testAlias()
  testAliasReturn()
  testAliasTuple()
  testAliasGeneric()
  testAliasFields()
  testStatic()
  testTypedesc()
  testLambdaIt()
  testArrow()
  testProc()
  testMacro()
  testTemplate()
  test5702()
  test9679()

testAll()

{.pop.}
