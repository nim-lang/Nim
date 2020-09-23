#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements `enumerate` syntactic sugar based on Nim's
## macro system.

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
    for i, x in enumerate(97, c):
      d.add((i, x))
    assert d == @[(97, 'a'), (98, 'b'), (99, 'c'), (100, 'd')]

  expectKind x, nnkForStmt
  # check if the starting count is specified:
  var countStart = if x[^2].len == 2: newLit(0) else: x[^2][1]
  result = newStmtList()
  # We strip off the first for loop variable and use it as an integer counter.
  # We must immediately decrement it by one, because it gets incremented before
  # the loop body - to be able to use the final expression in other macros.
  result.add newVarStmt(x[0], infix(countStart, "-", newLit(1)))
  var body = x[^1]
  if body.kind != nnkStmtList:
    body = newTree(nnkStmtList, body)
  body.insert(0, newCall(bindSym"inc", x[0]))
  var newFor = newTree(nnkForStmt)
  for i in 1..x.len-3:
    newFor.add x[i]
  # transform enumerate(X) to 'X'
  newFor.add x[^2][^1]
  newFor.add body
  result.add newFor
  # now wrap the whole macro in a block to create a new scope
  result = quote do:
    block: `result`
