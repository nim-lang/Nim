# Dump the contents of a PNimrodNode

import macros

template plus(a, b: expr): expr =
  a + b

macro call(e: expr): expr =
  return newCall("foo", newStrLitNode("bar"))
  
macro dumpAST(n: stmt): stmt =
  # dump AST as a side-effect and return the inner node
  echo n.toLisp
  echo n.toYaml

  var plusAst = getAst(plus(1, 2))
  echo plusAst.toLisp

  var callAst = getAst(call())
  echo callAst.toLisp

  var e = parseExpr("foo(bar + baz)")
  echo e.toLisp

  result = n[1]
  
dumpAST:
  proc add(x, y: int): int =
    return x + y
  
  proc sub(x, y: int): int = return x - y

