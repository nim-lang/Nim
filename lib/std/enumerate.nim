#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements enumeration APIs.

import std/private/since
import macros


macro enumerate*(x: ForLoopStmt): untyped {.since: (1, 3).} =
  ## Enumerating iterator for collections.
  ##
  ## It yields `(count, value)` tuples (which must be immediately unpacked).
  ## The default starting count `0` can be manually overridden if needed.
  runnableExamples:
    let a = [10, 20, 30]
    var b: seq[(int, int)]
    for i, x in enumerate(a):
      b.add((i, x))
    assert b == @[(0, 10), (1, 20), (2, 30)]

    let c = "abcd"
    var d: seq[(int, char)]
    for (i, x) in enumerate(97, c):
      d.add((i, x))
    assert d == @[(97, 'a'), (98, 'b'), (99, 'c'), (100, 'd')]

  template genCounter(x): untyped =
    # We strip off the first for loop variable and use it as an integer counter.
    # We must immediately decrement it by one, because it gets incremented before
    # the loop body - to be able to use the final expression in other macros.
    newVarStmt(x, infix(countStart, "-", newLit(1)))

  template genInc(x): untyped =
    newCall(bindSym"inc", x)

  expectKind x, nnkForStmt
  # check if the starting count is specified:
  var countStart = if x[^2].len == 2: newLit(0) else: x[^2][1]
  result = newStmtList()
  var body = x[^1]
  if body.kind != nnkStmtList:
    body = newTree(nnkStmtList, body)
  var newFor = newTree(nnkForStmt)
  if x.len == 3: # single iteration variable
    if x[0].kind == nnkVarTuple: # for (x, y, ...) in iter
      result.add genCounter(x[0][0])
      body.insert(0, genInc(x[0][0]))
      for i in 1 .. x[0].len-2:
        newFor.add x[0][i]
    else:
      error("Missing second for loop variable") # for x in iter
  else: # for x, y, ... in iter
    result.add genCounter(x[0])
    body.insert(0, genInc(x[0]))
    for i in 1 .. x.len-3:
      newFor.add x[i]
  # transform enumerate(X) to 'X'
  newFor.add x[^2][^1]
  newFor.add body
  result.add newFor
  # now wrap the whole macro in a block to create a new scope
  result = newBlockStmt(result)

macro staticUnroll*(x: ForLoopStmt): untyped =
  ## Also known as `static for` in some other languages.
  runnableExamples:
    var msg = ""
    for T in staticUnroll([int, float]):
      var a: T # a is gensym'd so won't cause a redifinition error
      proc fn() {.gensym.} = discard # gensym needed here
      proc fn2(a: T): auto = a # regular overloading here
      msg.add $T & " "
    assert msg == "int float "
    assert fn2(1.1) == 1.1 # `staticUnroll` is evaluated in caller scope

    # with 2 loop parameters, the 1st one is a const int indexing the element
    for i, T in staticUnroll([int, float, string]):
      when i == 0: assert T is int
      elif i == 1: assert T is float
      else: assert T is string

  runnableExamples:
    # example showing nested loops
    var msg = ""
    proc fn1(a: auto) = msg.add $("fn1", a)
    proc fn2(a: auto) = msg.add $("fn1", a)
    for fn in staticUnroll([fn1, fn2]):
      for T in staticUnroll([int, float]):
        fn(T.default)
    assert msg == """("fn1", 0)("fn1", 0.0)("fn1", 0)("fn1", 0.0)"""

  runnableExamples:
    # example showing passing untyped arguments to define variables
    for i, name in staticUnroll([name0, name1]):
      const name = i
    assert name1 == 1

  runnableExamples:
    template baz =
      for i, name in staticUnroll([name0, name1]):
        const name = i
      assert name1 == 1
    baz()
  # xxx maybe `fieldPairs`, `fields` implementation in compiler could reuse this trick
  expectKind x, nnkForStmt
  var varIndex: NimNode
  if x.len == 3: discard
  elif x.len == 4: varIndex = x[^4]
  else: doAssert false, $x.len
  result = newStmtList()
  let
    body = x[^1]
    elems = x[^2]
    varName = x[^3]
  for i, ai in elems[1]:
    if varIndex == nil:
      result.add quote do:
        template impl(`varName`) {.gensym.} = `body`
        impl(`ai`)
    else:
      let i2 = newLit(i)
      result.add quote do:
        template impl(`varIndex`, `varName`) {.gensym.} = `body`
        impl(`i2`, `ai`)
