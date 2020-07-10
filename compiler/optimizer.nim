#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Optimizer:
## - elide 'wasMoved(x); destroy(x)' pairs
## - recognize "all paths lead to 'wasMoved(x)'" <-- TODO.
## - elide 'destroy(x)' calls if only special literals are
##   assigned to 'x' and 'x' is not mutated or passed by 'var T'
##   to something else. Special literals are string literals or
##   arrays / tuples of string literals etc. <-- TODO.

import
  ast, astalgo, msgs, renderer, types, idents

from trees import exprStructuralEquivalent, getRoot

type
  Con = object
    wasMovedLocs: seq[PNode]
    toElide: seq[PNode]
    mainFlow: bool

proc invalidateWasMoved(c: var Con; x: PNode) =
  var i = 0
  while i < c.wasMovedLocs.len:
    if exprStructuralEquivalent(c.wasMovedLocs[i][1].skipAddr, x,
                                strictSymEquality = true):
      c.wasMovedLocs.del i
    else:
      inc i

proc wasMovedDestroyPair(c: var Con; d: PNode) =
  var i = 0
  while i < c.wasMovedLocs.len:
    if exprStructuralEquivalent(c.wasMovedLocs[i][1].skipAddr, d[1].skipAddr,
                                strictSymEquality = true):
      c.toElide.add c.wasMovedLocs[i]
      c.toElide.add d
      c.wasMovedLocs.del i
    else:
      inc i

proc analyse(c: var Con; n: PNode) =
  case n.kind
  of nkCallKinds:
    var special = false
    var reverse = false
    if n[0].kind == nkSym:
      let s = n[0].sym
      if s.magic == mWasMoved:
        if c.mainFlow:
          c.wasMovedLocs.add n
        special = true
      elif s.name.s == "=destroy":
        if c.mainFlow:
          c.wasMovedDestroyPair n
        special = true
      elif s.name.s == "=sink":
        reverse = true

    if not special:
      if not reverse:
        for i in 0 ..< n.len:
          analyse(c, n[i])
      else:
        #[ Test tmatrix.test3:
        Prevent this from being elided. We should probably
        find a better solution...

            `=sink`(b, - (
              let blitTmp = b;
              wasMoved(b);
              blitTmp + a)
            `=destroy`(b)

        ]#
        for i in countdown(n.len-1, 0):
          analyse(c, n[i])
      #if canRaise(n[0]): c.mainFlow = false

  of nkSym:
    # any usage of the location before destruction implies we
    # cannot elide the 'wasMoved(x)':
    c.invalidateWasMoved n

  of nkNone..pred(nkSym), succ(nkSym)..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
    discard "do not follow the construct"

  of nkAsgn, nkFastAsgn:
    # reverse order, see remark for `=sink`:
    analyse(c, n[1])
    analyse(c, n[0])

  of nkIfStmt, nkIfExpr, nkCaseStmt, nkTryStmt, nkWhileStmt,
     nkDefer, nkBreakStmt, nkReturnStmt, nkRaiseStmt:
    c.mainFlow = false
    for child in n: analyse(c, child)
  else:
    for child in n: analyse(c, child)

proc opt(c: Con; n, parent: PNode; parentPos: int) =
  template recurse() =
    let x = shallowCopy(n)
    for i in 0 ..< n.len:
      opt(c, n[i], x, i)
    parent[parentPos] = x

  case n.kind
  of nkCallKinds:
    if n in c.toElide:
      parent[parentPos] = newNodeI(nkEmpty, n.info)
    else:
      recurse()

  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef,
      nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
      nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
      nkExportStmt, nkPragma, nkCommentStmt, nkBreakState, nkTypeOfExpr:
    parent[parentPos] = n

  else:
    recurse()


proc optimize*(n: PNode): PNode =
  # optimize away simple 'wasMoved(x); destroy(x)' pairs.
  #[ Unfortunately this optimization is only really safe when no exceptions
     are possible, see for example:

  proc main(inp: string; cond: bool) =
    if cond:
      try:
        var s = ["hi", inp & "more"]
        for i in 0..4:
          use s
        consume(s)
        wasMoved(s)
      finally:
        destroy(s)

    Now assume 'use' raises, then we shouldn't do the 'wasMoved(s)'
  ]#
  var c: Con
  c.mainFlow = true
  analyse(c, n)
  if c.toElide.len > 0:
    result = shallowCopy(n)
    for i in 0 ..< n.safeLen:
      opt(c, n[i], result, i)
  else:
    result = n
