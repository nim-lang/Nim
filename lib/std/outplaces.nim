import std/macros
include system/inclrtl

proc outplaceImpl(arg, call: NimNode): NimNode =
  expectKind call, nnkCallKinds
  let tmp = genSym(nskVar, "outplaceResult")
  var callsons = call[0..^1]
  var found = false
  for i in 1..<len(callsons):
    if callsons[i].kind == nnkIdent and callsons[i].strVal == "_":
      callsons[i] = tmp
      found = true
      break
  if not found: callsons.insert(tmp, 1)
  result = newTree(nnkStmtListExpr,
    newVarStmt(tmp, arg),
    copyNimNode(call).add callsons,
    tmp)

proc replaceOutplace(lhs, n: NimNode): NimNode =
  case n.kind
  of nnkDotExpr, nnkBracketExpr:
    result = copyNimTree(n)
    result[0] = replaceOutplace(lhs, result[0])
  of nnkCall:
    result = outplaceImpl(lhs, n)
  of nnkCommand:
    result = outplaceImpl(lhs, n)
  else:
    doAssert false, "unexpected kind: " & $n.kind

macro `./`*(lhs, rhs): untyped {.since: (1, 1).} =
  ## Outplace operator: turns an `in-place`:idx: algorithm into one that works on
  ## a copy and returns this copy. A placeholder `_` can optionally be used to
  ## specify an output parameter of position > 0.
  ## **Since**: Version 1.2.
  runnableExamples:
    import algorithm, strutils
    doAssert @[2,1,3]./sort() == @[1,2,3]
    doAssert ""./addQuoted("foX").toUpper == "\"FOX\""
    doAssert "A"./addQuoted("foo").toUpper[0..1].toLower == "a\""
    proc bar(x: int, ret: var int) = ret += x
    doAssert 3./bar(4, _) == 3 + 4 # use placeholder `_` to specify a position > 0
    doAssert @[2,1,3]./sort(_) == @[1,2,3] # `_` works but unneeded in position 0
  result = copyNimTree(rhs)
  result = replaceOutplace(lhs, result)
