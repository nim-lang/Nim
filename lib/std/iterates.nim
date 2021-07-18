import std/macros

type IteratorError = object of Exception

proc replace(n: NimNode): NimNode =
  case n.kind
  of nnkContinueStmt:
    result = newTree(nnkReturnStmt, newEmptyNode())
  of nnkBreakStmt:
    result = quote do:
      raise newException(IteratorError, "")
  else:
    result = n
    for i in 0..<n.len:
      result[i] = n[i].replace

macro iterate*(x: ForLoopStmt): untyped =
  let lhs = x[0]
  let body = x[^1].replace
  let iterateArgs = x[^2]
  doAssert iterateArgs.len >= 2
  let call = iterateArgs[1]

  let formal = nnkFormalParams.newTree(newEmptyNode())
  doAssert iterateArgs.len == 2
  for i in 0..<x.len - 2:
    formal.add nnkIdentDefs.newTree(x[i], ident"auto", newEmptyNode())

  let anon = nnkLambda.newTree(
    newEmptyNode(),
    newEmptyNode(),
    newEmptyNode(),
    formal,
    newEmptyNode(),
    newEmptyNode(),
    body
  )

  let par = nnkPar.newTree(anon)
  if false:
    call.insert(1, par)
  else:
    let par2 = quote do:
      # cont = `par` # bug: doesn't work: Error: undeclared identifier: 'cont' (and would be ugly)
      `par` # bug: downside, is it requires all optional args passed
    call.add(par2)
  result = quote do:
    try:
      `call`
    except IteratorError:
      discard
