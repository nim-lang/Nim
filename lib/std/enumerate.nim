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

# FACTOR PRTEMP replaceIdentBySym
proc replaceIdent(n: NimNode, identOld: NimNode, nNew: NimNode): NimNode =
  case n.kind
  of nnkIdent: # TODO: nnkSym?
    if eqIdent(n, identOld): return nNew
    else: return n
  else:
    for i in 0..<len(n):
      n[i] = replaceIdent(n[i], identOld, nNew)
    return n

macro staticFor*(x: ForLoopStmt): untyped =
  runnableExamples:
    for i, T in staticFor([int, float]):
      when i == 0: assert T is int
      else: assert T is float

    proc fn1(x: auto): auto = x
    proc fn2(x: auto): auto = x * x
    # for i, fn in staticFor([fn1, fn2]):
    #   for j, T in staticFor([int, float]):
    #     let a = fn(T.default)

    #     const i2 = i + j
    #     echo ($bi, astToStr(bj), i, j, i2)

  # RENAME: unroll?
  expectKind x, nnkForStmt
  # check if the starting count is specified:
  var countStart = if x[^2].len == 2: newLit(0) else: x[^2][1]
  result = newStmtList()
  var body = x[^1].copyNimTree
  var elems = x[^2]
  var varIndex = x[0] # PRTEMP
  var varName = x[1] # PRTEMP
  let varIndex2 = genSym(nskConst, varIndex.strVal)
  for i, ai in elems[1]:
    echo (i, ai.repr)
    let i2 = newLit(i)
    var n2 = replaceIdent(body.copyNimTree, varName, ai)
    n2 = replaceIdent(n2, varIndex2, i2)
    let ret = quote do:
      template tmp =
        `n2`
      tmp
    # result.add n2
    result.add ret
  echo result.repr

when isMainModule:
  #[
  TODO: see also: fieldPairs, fields
  ]#
  for i, bi in staticFor([int, float]):
    for j, bj in staticFor([fn1, fn2]):
      const i2 = i + j
      echo ($bi, astToStr(bj), i, j, i2)

  for i, T in staticFor([int, float]):
    var z = i
    const z2 = i
    var z3: T
    echo (z, z2, i, $T, T.default)
    proc bar() {.gensym.} = echo (z,)
    bar()
    proc bar2(a: T) = echo ($T, "in bar")
  bar2(1)
  bar2(1.2)
