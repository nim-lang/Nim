import std/macros

{.experimental: "dynamicBindSym".}

macro dispatchImpl(scope: static NimScope, fun: untyped, args: varargs[untyped]): untyped =
  let sym = bindSym(fun.repr, scope=scope).getImpl
  let bodyParam = sym[3][^1][0]
  result = newCall(fun)
  for i, a in args:
    result.add:
      if a.kind == nnkStmtList:
        doAssert i == args.len-1
        newTree(nnkExprEqExpr, bodyParam, a)
      else:
        a

template dispatch*(fun: untyped, args: varargs[untyped]): untyped =
  dispatchImpl(getCurrentScope(), fun, args)

macro inspectImpl(scope: static NimScope, fun: untyped): untyped =
  let sym = bindSym(fun.repr, scope=scope).getImpl
  newLit sym.repr

template inspect*(fun: untyped): untyped = inspectImpl(getCurrentScope(), fun)

macro inspectWithoutScope*(fun: typed): untyped =
  let sym = fun.getImpl
  newLit sym.repr

macro arityImpl(scope: static NimScope, fun: untyped): untyped =
  let sym = bindSym(fun.repr, scope=scope).getImpl
  newLit sym[3].len - 1

template arity*(fun: untyped): untyped = arityImpl(getCurrentScope(), fun)

