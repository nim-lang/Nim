import std/macros
from std/strformat import `&`
import ./mgenast

block:
  macro bar(x0: static Foo, x1: Foo, x2: Foo, xignored: Foo): untyped =
    let s0 = "not captured!"
    let s1 = "not captured!"
    let xignoredLocal = kfoo4

    # newLit optional:
    let x3 = newLit kfoo4
    let x3b = kfoo4

    result = genAstOpt({kDirtyTemplate}, s1=true, s2="asdf", x0, x1=x1, x2, x3, x3b):
      doAssert not declared(xignored)
      doAssert not declared(xignoredLocal)
      (s1, s2, s0, x0, x1, x2, x3, x3b)

  let s0 = "caller scope!"

  doAssert bar(kfoo1, kfoo2, kfoo3, kfoo4) ==
    (true, "asdf", "caller scope!", kfoo1, kfoo2, kfoo3, kfoo4, kfoo4)

block:
  # doesn't have limitation mentioned in https://github.com/nim-lang/RFCs/issues/122#issue-401636535
  macro abc(name: untyped): untyped =
    result = genAst(name):
      type name = object

  abc(Bar)
  doAssert Bar.default == Bar()

block:
  # backticks parser limitations / ambiguities not an issue with `genAst`:
  # fix https://github.com/nim-lang/Nim/issues/10326
  # fix https://github.com/nim-lang/Nim/issues/9745
  type Foo = object
    a: int

  macro m1(): untyped =
    # result = quote do: # Error: undeclared identifier: 'a1'
    result = genAst:
      template `a1=`(x: var Foo, val: int) =
        x.a = val

  m1()
  var x0: Foo
  x0.a1 = 10
  doAssert x0 == Foo(a: 10)

block:
  # fix https://github.com/nim-lang/Nim/issues/7375
  macro fun(b: static[bool], b2: bool): untyped =
    result = newStmtList()
  macro foo(c: bool): untyped =
    var b = false
    result = genAst(b, c):
      fun(b, c)

  foo(true)

block:
  # fix https://github.com/nim-lang/Nim/issues/7589
  # since `==` works with genAst, the problem goes away
  macro foo2(): untyped =
    # result = quote do: # Error: '==' cannot be passed to a procvar
    result = genAst:
      `==`(3,4)
  doAssert not foo2()

block:
  # fix https://github.com/nim-lang/Nim/issues/7726
  macro foo(): untyped =
    let a = @[1, 2, 3, 4, 5]
    result = genAst(a, b = a.len): # shows 2 ways to get a.len
      (a.len, b)
  doAssert foo() == (5, 5)

block:
  # fix https://github.com/nim-lang/Nim/issues/9607
  proc fun1(info:LineInfo): string = "bar1"
  proc fun2(info:int): string = "bar2"

  macro bar2(args: varargs[untyped]): untyped =
    let info = args.lineInfoObj
    let fun1 = bindSym"fun1" # optional; we can remove this and also the
    # capture of fun1
    result = genAst(info, fun1):
      (fun1(info), fun2(info.line))
  doAssert bar2() == ("bar1", "bar2")

  macro bar(args: varargs[untyped]): untyped =
    let info = args.lineInfoObj
    let fun1 = bindSym"fun1"
    let fun2 = bindSym"fun2"
    result = genAstOpt({kDirtyTemplate}, info):
      (fun1(info), fun2(info.line))
  doAssert bar() == ("bar1", "bar2")

block:
  # fix https://github.com/nim-lang/Nim/issues/7889
  doAssert bindme2() == kfoo1
  doAssert bindme3() == kfoo1
  doAssert not compiles(bindme4()) # correctly gives Error: undeclared identifier: 'myLocalPriv'
  proc myLocalPriv2(): auto = kfoo2

  doAssert bindme5UseExpose() == kfoo1
  doAssert bindme5UseExposeFalse() == kfoo2
    # local `myLocalPriv2` hijacks symbol, probably not what user wants
    # by default as it's surprising for the macro writer

  bindme6UseExpose()
  bindme6UseExposeFalse()

block:
  macro mbar(x3: Foo, x3b: static Foo): untyped =
    var x1=kfoo3
    var x2=newLit kfoo3
    var x4=kfoo3
    var xLocal=kfoo3

    proc funLocal(): auto = kfoo4

    result = genAst(x1, x2, x3, x4):
      # local x1 overrides remote x1
      when false:
        # one advantage of using `kDirtyTemplate` is that these would hold:
        doAssert not declared xLocal
        doAssert not compiles(echo xLocal)
        # however, even without it, we at least correctly generate CT error
        # if trying to use un-captured symbol; this correctly gives:
        # Error: internal error: environment misses: xLocal
        echo xLocal

      proc foo1(): auto =
        # note that `funLocal` is captured implicitly, according to hygienic
        # template rules; with `kDirtyTemplate` it would not unless
        # captured in `genAst` capture list explicitly
        (a0: xRemote, a1: x1, a2: x2, a3: x3, a4: x4, a5: funLocal())

    return result

  proc main()=
    var xRemote=kfoo1
    var x1=kfoo2
    mbar(kfoo4, kfoo4)
    doAssert foo1() == (a0: kfoo1, a1: kfoo3, a2: kfoo3, a3: kfoo4, a4: kfoo3, a5: kfoo4)

  main()

block:
  # fix https://github.com/nim-lang/Nim/issues/8220
  macro foo(): untyped =
    # kDirtyTemplate needed here
    result = genAstOpt({kDirtyTemplate}):
      let bar = "Hello, World"
      &"Let's interpolate {bar} in the string"
  doAssert foo() == "Let's interpolate Hello, World in the string"


block: # nested application of genAst
  macro createMacro(name, obj, field: untyped): untyped =
    result = genAst(obj = newDotExpr(obj, field), lit = 10, name, field):
      # can't reuse `result` here, would clash
      macro name(arg: untyped): untyped =
        genAst(arg2=arg): # somehow `arg2` rename is needed
          (obj, astToStr(field), lit, arg2)

  var x = @[1, 2, 3]
  createMacro foo, x, len
  doAssert (foo 20) == (3, "len", 10, 20)

block: # test with kNoAutoNewLit
  macro bar(): untyped =
    let s1 = true
    template boo(x): untyped =
      fun(x)
    result = genAstOpt({kNoAutoNewLit}, s1=newLit(s1), s1b=s1): (s1, s1b)
  doAssert bar() == (true, 1)

block: # sanity check: check passing `{}` also works
  macro bar(): untyped =
    result = genAstOpt({}, s1=true): s1
  doAssert bar() == true
