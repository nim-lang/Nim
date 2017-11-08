#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module procs, operators and macros that provide *syntactic sugar* for
## the nim language.

import macros

type ListComprehension = object
var lc*: ListComprehension

macro `[]`*(lc: ListComprehension, comp, typ: untyped): untyped =
  ## List comprehension, returns a sequence. `comp` is the actual list
  ## comprehension, for example ``x | (x <- 1..10, x mod 2 == 0)``. `typ` is
  ## the type that will be stored inside the result seq.
  ##
  ## .. code-block:: nim
  ##
  ##   echo lc[x | (x <- 1..10, x mod 2 == 0), int]
  ##
  ##   const n = 20
  ##   echo lc[(x,y,z) | (x <- 1..n, y <- x..n, z <- y..n, x*x + y*y == z*z),
  ##           tuple[a,b,c: int]]

  expectLen(comp, 3)
  expectKind(comp, nnkInfix)
  expectKind(comp[0], nnkIdent)
  assert($comp[0].ident == "|")

  result = newCall(
    newDotExpr(
      newIdentNode("result"),
      newIdentNode("add")),
    comp[1])

  for i in countdown(comp[2].len-1, 0):
    let x = comp[2][i]
    expectMinLen(x, 1)
    if x[0].kind == nnkIdent and $x[0].ident == "<-":
      expectLen(x, 3)
      result = newNimNode(nnkForStmt).add(x[1], x[2], result)
    else:
      result = newIfStmt((x, result))

  result = newNimNode(nnkCall).add(
    newNimNode(nnkPar).add(
      newNimNode(nnkLambda).add(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        newNimNode(nnkFormalParams).add(
          newNimNode(nnkBracketExpr).add(
            newIdentNode("seq"),
            typ)),
        newEmptyNode(),
        newEmptyNode(),
        newStmtList(
          newAssignment(
            newIdentNode("result"),
            newNimNode(nnkPrefix).add(
              newIdentNode("@"),
              newNimNode(nnkBracket))),
          result))))

macro asArray*(targetType: untyped, values: typed): untyped =
  ## applies a type conversion to each of the elements in the specified
  ## array literal. Each element is converted to the ``targetType`` type..
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   let x = asArray(int, [0.1, 1.2, 2.3, 3.4])
  ##   doAssert x is array[4, int]
  ##
  ## Short notation for:
  ##
  ## .. code-block::
  ##   let x = [(0.1).int, (1.2).int, (2.3).int, (3.4).int]
  values.expectKind(nnkBracket)
  result = newNimNode(nnkBracket, lineInfoFrom=values)
  for i in 0 ..< len(values):
    var call = newNimNode(nnkCall, lineInfoFrom=values[i])
    call.add targetType
    call.add values[i]
    result.add call

when isMainModule:
  block: # asArray tests
    let x = asArray(int, [1.2, 2.3, 3.4, 4.5])
    doAssert x is array[4, int]
    let y = asArray(`$`, [1.2, 2.3, 3.4, 4.5])
    doAssert y is array[4, string]
