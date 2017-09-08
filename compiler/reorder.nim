
import intsets, ast, idents, algorithm, renderer, parser, ospaths, strutils, sequtils

type
  DepN = ref object
    pnode: PNode
    id, idx, lowLink: int
    onStack: bool
    kids: seq[DepN]
  DepG = seq[DepN]

proc newDepN(id: int, pnode: PNode): DepN =
  new(result)
  result.id = id
  result.pnode = pnode
  result.idx = -1
  result.lowLink = -1
  result.onStack = false
  result.kids = @[]

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
  of procDefs, nkMacroDef, nkTemplateDef:
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
        for i in 1..<a.len:
          if a[i].kind == nkEnumTy:
            for b in a[i]:
              decl(b)
          else:
            deps(a[i])
  of nkIdent: uses.incl n.ident.id
  of nkSym: uses.incl n.sym.name.id
  # of nkPtrTy, nkRefTy:
  #   assert n.len <= 1
  #   echo n
  #   if n.len > 0:
  #     deps(n[0])
  of nkAccQuoted: uses.incl accQuoted(n).id
  of nkOpenSymChoice, nkClosedSymChoice:
    uses.incl n.sons[0].sym.name.id
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse, nkStaticStmt:
    for i in 0..<len(n): computeDeps(n[i], declares, uses, topLevel)
  of nkPragma:
    let a = n.sons[0]
    if a.kind == nkExprColonExpr and a.sons[0].kind == nkIdent and 
       a.sons[0].ident.s == "pragma":
        decl(a.sons[1])
    else:
      for i in 0..<safeLen(n): deps(n[i])
  else:
    for i in 0..<safeLen(n): deps(n[i])

proc cleanPath(s: string): string =
  # Here paths may have the form A / B or "A/B"
  result = ""
  for c in s:
    if c != ' ' and c != '\"':
      result.add c

proc joinPath(parts: seq[string]): string =
  let nb = parts.len
  assert nb > 0
  if nb == 1:
    return parts[0]
  result = parts[0] / parts[1]
  for i in 2..<parts.len:
    result = result / parts[i]

proc getIncludePath(n: PNode, modulePath: string): string =
  let istr = n.renderTree.cleanPath
  let (pdir, _) = modulePath.splitPath
  let p = istr.split('/').joinPath.addFileExt("nim")
  result = pdir / p

proc hasIncludes(n:PNode): bool =
  for a in n:
    if a.kind == nkIncludeStmt:
      return true

proc expandIncludes(n: PNode, modulePath: string): PNode =
  # Parses includes and injects them in the current tree
  if not n.hasIncludes:
    return n
  result = newNodeI(nkStmtList, n.info)
  for a in n:
    if a.kind == nkIncludeStmt:
      # echo a
      for b in a:
        let fn = getIncludePath(b, modulePath)
        try:
          let str = readFile(fn)
          var cache = newIdentCache()
          let nn = parseString(str, cache, fn)
          let nnn = expandIncludes(nn, fn)
          for bb in nnn:
            result.add bb
        except:
          # echo "failed expanding " & fn
          result.add a
    elif a.kind in {nkWhenStmt}:
      var aa = newNodeI(a.kind, a.info)
      for b in a:
        # echo b
        var bb = newNodeI(b.kind, b.info)
        if bb.kind == nkElifBranch:
          bb.add b.sons[0]
          bb.add expandIncludes(b.sons[1], modulePath)
        else:
          bb.add expandIncludes(b.sons[0], modulePath)
        aa.add bb
      result.add aa
    else:
      result.add a

proc splitSections(n: PNode): PNode =
  # Split typeSections and ConstSections into 
  # sections that contain only one definition
  assert n.kind == nkStmtList
  result = newNodeI(nkStmtList, n.info)
  for a in n:
    if a.kind in {nkTypeSection, nkConstSection} and a.len > 1:
      for b in a:
        var s = newNode(a.kind)
        s.add b
        result.add s
    else:
      result.add a

proc haveSameKind(dns: seq[DepN]): bool =
  # Check if all the nodes in a strongly connected
  # component have the same kind
  result = true
  let kind = dns[0].pnode.kind
  for dn in dns:
    if dn.pnode.kind != kind:
      return false
    
proc mergeSections(comps: seq[seq[DepN]], res: PNode) =
  # Merges typeSections and ConstSections when they form 
  # a strong component (ex: circular type definition)
  for c in comps:
    assert c.len > 0
    if c.len == 1:
      res.add c[0].pnode
    else:
      let fstn = c[0].pnode
      let kind = fstn.kind
      if kind in {nkTypeSection, nkConstSection} and haveSameKind(c):
        var sn = newNode(kind)
        for dn in c:
          sn.add dn.pnode.sons[0]
        res.add sn
      else:
        # echo "OUUUUPs"
        # echo c.len
        # if c[0].pnode.kind in procDefs and c.haveSameKind:
          # We have an unexpected circular dependancy
          # Keep the original relative order
          # echo "************************************************************************"
          let cs = c.sortedByIt(it.id)
          # for dn in cs:
          #   echo dn.pnode
          #   echo dn.pnode.kind
          #   echo dn.id
          #   res.add dn.pnode
          
          var i = 0
          while i < cs.len:
            if cs[i].pnode.kind in {nkTypeSection, nkConstSection}:
              let ckind = cs[i].pnode.kind
              var sn = newNode(ckind)
              sn.add cs[i].pnode[0]
              inc i
              while cs[i].pnode.kind == ckind and i < cs.len:
                sn.add cs[i].pnode[0]
                inc i
              res.add sn
            else:
              res.add cs[i].pnode
              inc i

proc hasImportStmt(n: PNode): bool = 
  case n.kind
  of nkImportStmt:
    return true
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse, nkStaticStmt:
    for a in n:
      if a.hasImportStmt:
        return true
  else:
    result = false

const extandedProcDefs = procDefs + {nkMacroDef,  nkTemplateDef}

proc hasAccQuoted(n: PNode): bool =
  if n.kind == nkAccQuoted:
    return true
  for a in n:
    if hasAccQuoted(a):
      return true

proc hasAccQuotedDef(n: PNode): bool = 
  case n.kind
  of extandedProcDefs:
    result = n[0].hasAccQuoted
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse, nkStaticStmt:
    for a in n:
      if a.hasAccQuoted:
        return true
  else:
    result = false

proc hasBody(n: PNode, shouldHave: bool): bool = 
  case n.kind
  of extandedProcDefs:
    if shouldHave:
      result = n[^1].kind == nkStmtList
    else:
      result = n[^1].kind == nkEmpty
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse, nkStaticStmt:
    for a in n:
      if a.hasBody(shouldHave):
        return true
  else:
    result = false
proc intersects(s1, s2: IntSet): bool =
  for a in s1:
    if s2.contains(a):
      return true

proc buildGraph(n: PNode, deps: seq[(IntSet, IntSet)]): DepG =
  # Build a dependency graph
  result = newSeqOfCap[DepN](deps.len)
  for i in 0..<deps.len:
    result.add newDepN(i, n.sons[i])
  for i in 0..<deps.len:
    var n = result[i]
    let uses = deps[i][1]
    for j in 0..<deps.len:
      if i == j: continue
      let declares = deps[j][0]
      if j < i and result[j].pnode.hasImportStmt:
        n.kids.add result[j]
      elif j < i and n.pnode.hasBody(true) and result[j].pnode.hasAccQuotedDef:
        n.kids.add result[j]
      elif j < i and n.pnode.hasBody(true) and result[j].pnode.hasBody(false) and
        intersects(deps[i][0], declares):
          n.kids.add result[j]
      else:
        for d in declares:
          if uses.contains(d):
            n.kids.add result[j]

proc strongConnect(v: var DepN, idx: var int, s: var seq[DepN], 
                   res: var seq[seq[DepN]]) =
  # Recursive part of trajan's algorithm
  v.idx = idx
  v.lowLink = idx
  inc idx
  s.add v
  v.onStack = true
  for w in v.kids.mitems:
    if w.idx < 0:
      strongConnect(w, idx, s, res)
      v.lowLink = min(v.lowLink, w.lowLink)
    elif w.onStack:
      v.lowLink = min(v.lowLink, w.idx)
  if v.lowLink == v.idx:
    var comp = newSeq[DepN]()
    while true:
      var w = s.pop
      w.onStack = false
      comp.add w
      if w.id == v.id: break
    res.add comp

proc getStrongComponents(g: var DepG): seq[seq[DepN]] =
  ## Tarjan's algorithm. Performs a topological sort 
  ## and detects strongly connected components.
  result = newSeq[seq[DepN]]()
  var s = newSeq[DepN]()
  var idx = 0
  for v in g.mitems:
    if v.idx < 0:
      strongConnect(v, idx, s, result)

proc hasForbiddenPragma(n: PNode): bool =
  # Checks if the tree node has some pragmas that do not
  # play well with reordering, like the push/pop pragma
  for a in n:
    if a.kind == nkPragma and a[0].kind == nkIdent and 
        a[0].ident.s == "push":
          return true

proc reorder*(n: PNode, modulePath: string): PNode =
  if n.hasForbiddenPragma:
    return n
  let n = splitSections(expandIncludes(n, modulePath))
  result = newNodeI(nkStmtList, n.info)
  var deps = newSeq[(IntSet, IntSet)](n.len)
  for i in 0..<n.len:
    deps[i][0] = initIntSet()
    deps[i][1] = initIntSet()
    computeDeps(n[i], deps[i][0], deps[i][1], true)

  var g = buildGraph(n, deps)
  let comps = getStrongComponents(g)
  mergeSections(comps, result)