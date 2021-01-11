## This module contains `Loop unrolling <https://en.wikipedia.org/wiki/Loop_unrolling>`_.
import macros


macro unrollIt*(x: ForLoopStmt) =
  ## Compile-time macro-unrolled `for` loops.
  ##
  ## The loop is unrolled into a single iteration,
  ## so other macros and templates can still see it as a vanilla for loop,
  ## and the scope reaches until the end of the loop body like other for loops:
  ##
  ## .. code-block:: nim
  ##   for i in unrollIt([0, 1, 2, 3]): echo it
  ##
  ## Expands to:
  ##
  ## .. code-block:: nim
  ##   for i in items([0, 1, 2, 3]):
  ##     var it = 0
  ##     echo it
  ##     it = 1
  ##     echo it
  ##     it = 2
  ##     echo it
  ##     it = 3
  ##     echo it
  ##     break
  ##
  ## Another example:
  ##
  ## .. code-block:: nim
  ##   for i in unrollIt([('a', true), ('b', false)]): echo it
  ##
  ## Expands to:
  ##
  ## .. code-block:: nim
  ##   for i in items([('a', true), ('b', false)]):
  ##     var it = ('a', true)
  ##     echo it
  ##     it = ('b', false)
  ##     echo it
  ##     break
  ##
  ## Inside the unrolled body you can use the variable `it`,
  ## only the `it` variable is allocated by the macro for minimal overhead,
  ## this does not mutate nor copy the iterable, the macro works for any target,
  ## the items inside the iterable must be assignable to a `var`.
  expectKind x, nnkForStmt
  result = newStmtList()
  var body = newStmtList()
  var itDeclared = false
  for i in 0 ..< x[^2][^1].len:
    if itDeclared:
      if x[^2][^1].len > i:
        body.add nnkAsgn.newTree(newIdentNode("it"), x[^2][^1][i])
    else:
      body.add newVarStmt(newIdentNode("it"), x[^2][^1][0])
      itDeclared = true
    body.add x[^1]
  body.add nnkBreakStmt.newTree(newEmptyNode())
  var newFor = newTree(nnkForStmt)
  newFor.add x[0]
  newFor.add x[^2][^1]
  newFor.add body
  result.add newFor
