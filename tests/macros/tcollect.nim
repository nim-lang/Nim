discard """
  output: '''@[2, 3, 4, 2, 3, 4, 2, 3, 4, 2, 3, 4, 2, 3, 4]
@[0, 1, 2, 3]'''
"""

const data = [1,2,3,4,5,6]

import macros

macro collect(body): untyped =
  # analyse the body, find the deepest expression 'it' and replace it via
  # 'result.add it'
  let res = genSym(nskVar, "collectResult")

  when false:
    proc detectForLoopVar(n: NimNode): NimNode =
      if n.kind == nnkForStmt:
        result = n[0]
      else:
        for x in n:
          result = detectForLoopVar(x)
          if result != nil: return result
        return nil

  proc t(n, res: NimNode): NimNode =
    case n.kind
    of nnkStmtList, nnkStmtListExpr, nnkBlockStmt, nnkBlockExpr,
       nnkWhileStmt,
       nnkForStmt, nnkIfExpr, nnkIfStmt, nnkTryStmt, nnkCaseStmt,
       nnkElifBranch, nnkElse, nnkElifExpr:
      result = copyNimTree(n)
      if n.len >= 1:
        result[^1] = t(n[^1], res)
    else:
      if true: #n == it:
        template adder(res, it) =
          res.add it
        result = getAst adder(res, n)
      else:
        result = n

  when false:
    let it = detectForLoopVar(body)
    if it == nil: error("no for loop in body", body)

  let v = newTree(nnkVarSection,
     newTree(nnkIdentDefs, res, newTree(nnkBracketExpr, bindSym"seq",
     newCall(bindSym"type", body)), newEmptyNode()))

  result = newTree(nnkStmtListExpr, v, t(body, res), res)
  #echo repr result

let stuff = collect:
  var i = -1
  while i < 4:
    inc i
    for it in data:
      if it < 5 and it > 1:
        it

echo stuff

echo collect(for i in 0..3: i)
