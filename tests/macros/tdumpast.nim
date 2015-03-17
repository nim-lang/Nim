# Dump the contents of a NimNode

import macros

template plus(a, b: expr): expr {.dirty} =
  a + b

macro call(e: expr): expr =
  result = newCall("foo", newStrLitNode("bar"))

macro dumpAST(n: stmt): stmt {.immediate.} =
  # dump AST as a side-effect and return the inner node
  let n = callsite()
  echo n.lispRepr
  echo n.treeRepr

  var plusAst = getAst(plus(1, 2))
  echo plusAst.lispRepr

  var callAst = getAst(call())
  echo callAst.lispRepr

  var e = parseExpr("foo(bar + baz)")
  echo e.lispRepr

  result = n[1]

dumpAST:
  proc add(x, y: int): int =
    return x + y

  proc sub(x, y: int): int = return x - y

