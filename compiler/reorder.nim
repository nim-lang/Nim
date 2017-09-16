
import intsets, tables, ast, idents, renderer

const
  nfTempMark = nfTransf
  nfPermMark = nfNoRewrite

proc accQuoted(n: PNode): PIdent =
  var id = ""
  for i in 0 .. <n.len:
    let x = n[i]
    case x.kind
    of nkIdent: id.add(x.ident.s)
    of nkSym: id.add(x.sym.name.s)
    else: discard
  result = getIdent(id)

proc addDecl(n: PNode; declares: var IntSet) =
  case n.kind
  of nkPostfix: addDecl(n[1], declares)
  of nkPragmaExpr: addDecl(n[0], declares)
  of nkIdent:
    declares.incl n.ident.id
  of nkSym:
    declares.incl n.sym.name.id
  of nkAccQuoted:
    declares.incl accQuoted(n).id
  else: discard

proc computeDeps(n: PNode, declares, uses: var IntSet; topLevel: bool) =
  template deps(n) = computeDeps(n, declares, uses, false)
  template decl(n) =
    if topLevel: addDecl(n, declares)
  case n.kind
  of procDefs:
    decl(n[0])
    for i in 1..bodyPos: deps(n[i])
  of nkLetSection, nkVarSection, nkUsingStmt:
    for a in n:
      if a.kind in {nkIdentDefs, nkVarTuple}:
        for j in countup(0, a.len-3): decl(a[j])
        for j in a.len-2..a.len-1: deps(a[j])
  of nkConstSection, nkTypeSection:
    for a in n:
      if a.len >= 3:
        decl(a[0])
        for i in 1..<a.len: deps(a[i])
  of nkIdent: uses.incl n.ident.id
  of nkSym: uses.incl n.sym.name.id
  of nkAccQuoted: uses.incl accQuoted(n).id
  of nkOpenSymChoice, nkClosedSymChoice:
    uses.incl n.sons[0].sym.name.id
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse:
    for i in 0..<len(n): computeDeps(n[i], declares, uses, topLevel)
  else:
    for i in 0..<safeLen(n): deps(n[i])

proc visit(i: int; all, res: PNode; deps: var seq[(IntSet, IntSet)]): bool =
  let n = all[i]
  if nfTempMark in n.flags:
    # not a DAG!
    return true
  if nfPermMark notin n.flags:
    incl n.flags, nfTempMark
    var uses = deps[i][1]
    for j in 0..<all.len:
      if j != i:
        let declares = deps[j][0]
        for d in declares:
          if uses.contains(d):
            let oldLen = res.len
            if visit(j, all, res, deps):
              result = true
              # rollback what we did, it turned out to be a dependency that caused
              # trouble:
              for k in oldLen..<res.len:
                res.sons[k].flags = res.sons[k].flags - {nfPermMark, nfTempMark}
              if oldLen != res.len: res.sons.setLen oldLen
            break
    n.flags = n.flags + {nfPermMark} - {nfTempMark}
    res.add n

proc reorder*(n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  var deps = newSeq[(IntSet, IntSet)](n.len)
  for i in 0..<n.len:
    deps[i][0] = initIntSet()
    deps[i][1] = initIntSet()
    computeDeps(n[i], deps[i][0], deps[i][1], true)

  for i in 0 .. n.len-1:
    discard visit(i, n, result, deps)
  for i in 0..<result.len:
    result.sons[i].flags = result.sons[i].flags - {nfTempMark, nfPermMark}
  when false:
    # reverse the result:
    let L = result.len-1
    for i in 0 .. result.len div 2:
      result.sons[i].flags = result.sons[i].flags - {nfTempMark, nfPermMark}
      result.sons[L - i].flags = result.sons[L - i].flags - {nfTempMark, nfPermMark}
      swap(result.sons[i], result.sons[L - i])
  #echo result
