import macros

# TODO: make this public in subsequent PR
macro varargsToTuple(args:varargs[untyped]):untyped=
  result = newTree(nnkTupleConstr)
  if args.len != 1:
    for a in args:
      result.add a
  else:
    # PENDING https://github.com/nim-lang/Nim/issues/8706
    if args[0].kind != nnkHiddenStdConv:
        result.add args[0]

macro lambdaEval*(lambda: untyped, arg:tuple):untyped=
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
  expectKind(arg, nnkTupleConstr)
  case lambda[1].kind
  of nnkPar: # (a, b) => expr
    if lambda[1].len != arg.len:
      error("size mismatch: lambda:" & $lambda[1].len & " arg:" & $arg.len)
    for i in 0..<lambda[1].len:
      ret.add newLetStmt(lambda[1][i], arg[i])
  of nnkIdent: # a => expr
      if arg.len != 1:
        error("size mismatch: " & $arg.len)
      ret.add newLetStmt(lambda[1], arg[0])
  else:
    error("expected " & ${nnkPar,nnkIdent} & " got " & $lambda[1].kind)

  ret.add lambda[2]
  result = newBlockStmt(ret)

macro makeLambda*(lambdaFun: untyped, lambdaAlias:untyped): untyped =
  ## convenience macro allowing one to use ``lambda(arg)`` instead of
  ## ``lambdaEval(fun, arg)``
  runnableExamples:
    block:
      template testCallFun[T](fun: untyped, a:T): auto =
        makeLambda(fun, lambda)
        lambda(lambda(a))
      doAssert testCallFun(x => x * 3, 2) == (2 * 3) * 3

    block:
      template testCallFun2[T](fun: untyped, a:T, b:T): auto =
        makeLambda(fun, lambda)
        lambda(a, b)
      doAssert testCallFun2((u,v) => u*v, 10, 11) == 10 * 11

  expectKind(lambdaAlias, nnkIdent)
  result = quote do:
    template `lambdaAlias`(args:varargs[untyped]): untyped =
      lambdaEval(`lambdaFun`, varargsToTuple(args))

when isMainModule:
  # PENDING https://github.com/nim-lang/Nim/issues/7280
  block lambdaEvalTest:
    discard lambdaEval(a => a, (0,))
  block makeLambdaTest:
    makeLambda(a => a, _)
