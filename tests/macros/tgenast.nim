import std/macros

block:
  type Foo = enum kfoo0, kfoo1, kfoo2, kfoo3, kfoo4

  macro bar(x0: static Foo, x1: Foo, x2: Foo, xignored: Foo): untyped =
    let s0 = "not captured!"
    let s1 = "not captured!"
    let xignoredLocal = kfoo4
    let x3 = newLit kfoo4
    result = genAst(s1=2, s2="asdf", x0=newLit x0, x1=x1, x2, x3) do:
      doAssert not declared(xignored)
      doAssert not declared(xignoredLocal)
      (s1, s2, s0, x0, x1, x2, x3)

  let s0 = "caller scope!"

  doAssert bar(kfoo1, kfoo2, kfoo3, kfoo4) ==
    (2, "asdf", "caller scope!", kfoo1, kfoo2, kfoo3, kfoo4)

block:
  # doesn't have limitation mentioned in https://github.com/nim-lang/RFCs/issues/122#issue-401636535
  macro abc(name: untyped): untyped =
    result = genAst(name):
      type name = object

  abc(Bar)
  doAssert Bar.default == Bar()

import std/strformat

block:
  # fix https://github.com/nim-lang/Nim/issues/8220
  macro foo(): untyped =
    result = genAst do:
      let bar = "Hello, World"
      &"Let's interpolate {bar} in the string"
  doAssert foo() == "Let's interpolate Hello, World in the string"

block:
  # backticks parser limitations / ambiguities not an issue with `genAst`:
  # fix https://github.com/nim-lang/Nim/issues/10326
  # fix https://github.com/nim-lang/Nim/issues/9745
  type Foo = object
    a: int

  macro m1(): untyped =
    # result = quote do: # Error: undeclared identifier: 'a1'
    result = genAst do:
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
    result = genAst(b = newLit b, c) do:
      fun(b, c)

  foo(true)

when true:
  # fix https://github.com/nim-lang/Nim/issues/7889
  from mgenast import bindme
  bindme()

block:
  # fix https://github.com/nim-lang/Nim/issues/7589
  # since `==` works with genAst, the problem goes away
  macro foo2(): untyped =
    # result = quote do: # Error: '==' cannot be passed to a procvar
    result = genAst do:
      `==`(3,4)
  doAssert not foo2()

block:
  # fix https://github.com/nim-lang/Nim/issues/7726
  macro foo(): untyped =
    let a = @[1, 2, 3, 4, 5]
    result = genAst(a, b = a.len) do: # shows 2 ways to get a.len
      (a.len, b)
  doAssert foo() == (5, 5)

block:
  # fix https://github.com/nim-lang/Nim/issues/9607
  proc fun1(info:LineInfo): string = "bar1"
  proc fun2(info:int): string = "bar2"
  macro bar(args: varargs[untyped]): untyped =
    let info = args.lineInfoObj
    let fun1 = bindSym"fun1"
    let fun2 = bindSym"fun2"
    result = genAst(info = newLit info) do:
      (fun1(info), fun2(info.line))
  doAssert bar() == ("bar1", "bar2")


