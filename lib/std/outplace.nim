import std/macros
include system/inclrtl

const dotLevel = {nnkDotExpr, nnkBracketExpr}
const op = ".>"

proc outplaceImpl(arg, call: NimNode): NimNode =
  var call = call
  if call.kind == nnkIdent:
    call = newTree(nnkCall, call)
  else:
    expectKind call, nnkCallKinds
  var callsons = call[0..^1]
  var found = false
  for i in 1..<len(callsons):
    if callsons[i].kind == nnkIdent and callsons[i].strVal == "_":
      callsons[i] = arg
      found = true
      break
  if not found: callsons.insert(arg, 1)
  result = copyNimNode(call).add callsons

proc doMerge(root: NimNode, n: NimNode, tmp: NimNode): NimNode =
  if n.kind == nnkIdent or n.kind in {nnkCall, nnkCommand} and n[0].kind == nnkIdent:
    root.add outplaceImpl(tmp, n)
    return tmp
  result = n
  result[0] = doMerge(root, n[0], tmp)

# type State = ref object
#   result: NimNode
#   n: NimNode
#   lhs: NimNode

proc processMove(lhs: var NimNode, isAddr: var bool) =
  isAddr = lhs.kind == nnkDotExpr and lhs[1].kind == nnkIdent and lhs[1].strVal == "move2"
  if isAddr:
    lhs[1] = newIdentNode("addr")

proc replaceChains2(result: NimNode, n: NimNode, lhs: var NimNode, isAddr: var bool) =
  if n.kind == nnkInfix and n[0].strVal == op:
    replaceChains2(result, n[1], lhs, isAddr)
    var tmp = lhs
    if lhs.kind != nnkSym and not isAddr:
      tmp = genSym(nskVar, "tmp")
      processMove(lhs, isAddr)
      # isAddr = lhs.kind == nnkDotExpr and lhs[1].kind == nnkIdent and lhs[1].strVal == "move2"
      # if isAddr:
      #   lhs[1] = newIdentNode("addr")
      result.add newVarStmt(tmp, lhs)
      if isAddr:
        tmp = newTree(nnkBracketExpr, [tmp])
    else:
      isAddr = false
    lhs = doMerge(result, n[2], tmp)
  else:
    lhs = n

macro `.>`*(lhs, rhs): untyped {.since: (1, 1).} =
  ## Outplace operator: turns an `in-place`:idx: algorithm into one that works on
  ## a copy and returns this copy. A placeholder `_` can optionally be used to
  ## specify an output parameter of position > 0. Intermediate copies are
  ## avoided when possible.
  ##
  ## **Since**: Version 1.2.
  runnableExamples:
    import algorithm, strutils
    doAssert @[2,1,3].>sort() == @[1,2,3]
    doAssert "".>addQuoted("foX").toUpper == "\"FOX\""
    doAssert "A".>addQuoted("foo").toUpper[0..1].toLower == "a\""
    proc bar(x: int, ret: var int) = ret += x
    doAssert 3.>bar(4, _) == 3 + 4 # use placeholder `_` to specify a position > 0
    doAssert @[2,1,3].>sort(_) == @[1,2,3] # `_` works but unneeded in position 0
  # 1st, reconstruct
  var n = newTree(nnkInfix, @[ident(op), lhs, rhs])
  result = newStmtList()
  var lhs: NimNode
  var isAddr = false
  replaceChains2(result, n, lhs, isAddr)
  processMove(lhs, isAddr)

  result = quote do:
    block: # CHECKME
      `result`
      `lhs`

