discard """
  nimout: '''initApple
deinitApple
Coral
enum
  redCoral, blackCoral'''
  output: '''TFoo
TBar'''
"""

# bug #1319

import macros

type
  TTextKind = enum
    TFoo, TBar

macro test: untyped =
  var x = @[TFoo, TBar]
  result = newStmtList()
  for i in x:
    result.add newCall(newIdentNode("echo"),
      case i
      of TFoo:
        bindSym("TFoo")
      of TBar:
        bindSym("TBar"))

test()

# issue 7827, bindSym power up
{.experimental: "dynamicBindSym".}
type
  Apple = ref object
    name: string
    color: int
    weight: int

proc initApple(name: string): Apple =
  discard

proc deinitApple(x: Apple) =
  discard

macro wrapObject(obj: typed, n: varargs[untyped]): untyped =
  let m = n[0]
  for x in m:
    var z = bindSym x
    echo z.repr

wrapObject(Apple):
  initApple
  deinitApple

type
  Coral = enum
    redCoral
    blackCoral

macro mixer(): untyped =
  let m = "Co" & "ral"
  let x = bindSym(m)
  echo x.repr
  echo getType(x).repr

mixer()

import ./mbindsym

block:
  # `getCurrentScope` allows passing templates and macros to another macro even when all
  # parameters are optional or untyped, by passing them as `untyped` and accessing them
  # via `bindSym(ident, scope)` in the callee
  # Example use case: debugging / introspection
  proc fun1(): auto = 1
  template fun2(): untyped = (1,2)
  template fun3(a1: int): untyped = discard
  template fun4(a1: int, a2: int): untyped = discard
  template fun4b(a1 = 1, a2 = "bac"): untyped = discard
  macro fun5(a1 = 1, a2 = "bac"): untyped = discard
  macro fun6(a1: int): untyped = discard
  # macro fun7(a1: int = 12, body: untyped): untyped = discard
  macro fun7(a0 = 1, body: untyped): untyped = discard

  const a = 1+2
  type Foo = object
    v1, v2: int

  # echo inspect(fun1) # to print
  discard inspect(fun1)
  discard inspect(fun2)
  discard inspect(a)
  discard inspect(Foo)
  discard inspect(fun4b)
  discard inspect(fun5)
  discard inspect(fun6)
  discard inspect(fun7)

  when false:
    # this would not be possible without `getCurrentScope` as it would require
    # passing `fun` as a `typed` param, but then the compiler would error
    # after trying to call the template/macro directly:
    discard inspectWithoutScope(fun2) # Error: node is not a symbol
    discard inspectWithoutScope(a) # ditto
    discard inspectWithoutScope(fun4b) # ditto
    discard inspectWithoutScope(fun5) # Error: in call 'fun5' got -1, but expected 2 argument(s)
    discard inspectWithoutScope(fun7) # ditto
  # these work with `inspectWithoutScope`:
  discard inspectWithoutScope(fun1) # ok
  discard inspectWithoutScope(fun4) # ok
  discard inspectWithoutScope(fun6) # ok

  # example use case: type traits
  doAssert arity(fun2) == 0
  doAssert arity(fun3) == 1
  doAssert arity(fun4) == 2

block:
  # As another application, this can be used to implement a workaround for this:
  # [optional params before `untyped` body - Nim forum](https://forum.nim-lang.org/t/4970)
  proc getA1Def(): auto = 12

  macro foo(a0: bool, a1 = getA1Def(), a2 = "ba", body: untyped): untyped =
    result = newStmtList()
    result.add body
    result.add nnkTupleConstr.newTree [a0, a1, a2]

  var count = 0
  let ret = foo.dispatch(true, a2 = "bo"):
    count.inc

  doAssert count == 1
  doAssert ret == (true, 12, "bo")

  macro foo2(body: untyped): untyped = newLit body.repr
  let ret2 = dispatch(foo2, (echo 12))
  doAssert ret2 == "(echo 12)"

block:
  proc main() =
    # also works inside a proc
    template fun5(a1: int, a2: int): untyped = discard
    doAssert arity(fun5) == 2

