import macros

macro lambdaEval*(lambda: untyped, arg:typed):untyped=
  ## allows using zero-cost lambda expressions ``a=>b`` in templates. Type
  ## inference is done at evaluation site, so user doesn't need to specify
  ## types in the lambda expression.
  runnableExamples:
    template testCallFun[T](fun: untyped, a:T): auto =
      lambdaEval(fun, lambdaEval(fun, a))
    doAssert testCallFun(x => x * 3, 2) == (2 * 3) * 3

  if $lambda[0] != "=>":
    error("Expected `=>` got " & $lambda[0])
  var ret = newStmtList()
  ret.add newLetStmt(lambda[1], arg)
  ret.add lambda[2]
  result = newBlockStmt(ret)

macro makeLambda*(lambdaFun: untyped, lambdaAlias:untyped): untyped =
  ## convenience macro allowing one to use ``lambda(arg)`` instead of
  ## ``lambdaEval(fun, arg)``
  runnableExamples:
    template testCallFun[T](fun: untyped, a:T): auto =
      makeLambda(fun, lambda)
      lambda(lambda(a))
    doAssert testCallFun(x => x * 3, 2) == (2 * 3) * 3

  expectKind(lambdaAlias, nnkIdent)
  result = quote do:
    template `lambdaAlias`(arg:untyped): untyped = lambdaEval(`lambdaFun`, arg)

when isMainModule:
  # PENDING https://github.com/nim-lang/Nim/issues/7280
  block lambdaEvalTest:
    discard lambdaEval(a => a, 0)
  block makeLambdaTest:
    makeLambda(a => a, _)
