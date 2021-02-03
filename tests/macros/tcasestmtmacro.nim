discard """
  output: '''
yes
'''
"""

{.experimental: "caseStmtMacros".}

import macros

macro `case`(n: tuple): untyped =
  result = newTree(nnkIfStmt)
  let selector = n[0]
  for i in 1 ..< n.len:
    let it = n[i]
    case it.kind
    of nnkElse, nnkElifBranch, nnkElifExpr, nnkElseExpr:
      result.add it
    of nnkOfBranch:
      for j in 0..it.len-2:
        let cond = newCall("==", selector, it[j])
        result.add newTree(nnkElifBranch, cond, it[^1])
    else:
      error "custom 'case' for tuple cannot handle this node", it

var correct = false

case ("foo", 78)
of ("foo", 78):
  correct = true
  echo "yes"
of ("bar", 88): echo "no"
else: discard

doAssert correct
