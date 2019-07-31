# Dump the contents of a NimNode

import macros

template plus(a, b: untyped): untyped {.dirty} =
  a + b

macro call(e: untyped): untyped =
  result = newCall("foo", newStrLitNode("bar"))

macro dumpAST(n: untyped): untyped =
  # dump AST as a side-effect and return the inner node
  echo n.lispRepr
  echo n.treeRepr

  var plusAst = getAst(plus(1, 2))
  echo plusAst.lispRepr

  var callAst = getAst(call(4))
  echo callAst.lispRepr

  var e = parseExpr("foo(bar + baz)")
  echo e.lispRepr

  result = n[1]

dumpAST:
  proc add(x, y: int): int =
    return x + y

  proc sub(x, y: int): int = return x - y
