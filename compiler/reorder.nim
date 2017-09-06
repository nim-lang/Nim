
import intsets, ast, idents, algorithm

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
        for i in 1..<a.len: deps(a[i])
  of nkIdent: uses.incl n.ident.id
  of nkSym: uses.incl n.sym.name.id
  of nkAccQuoted: uses.incl accQuoted(n).id
  of nkOpenSymChoice, nkClosedSymChoice:
    uses.incl n.sons[0].sym.name.id
  of nkStmtList, nkStmtListExpr, nkWhenStmt, nkElifBranch, nkElse, nkStaticStmt:
    for i in 0..<len(n): computeDeps(n[i], declares, uses, topLevel)
  else:
    for i in 0..<safeLen(n): deps(n[i])

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
        for dn in c:
          res.add dn.pnode

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

proc reorder*(n: PNode): PNode =
  let n = splitSections(n)
  result = newNodeI(nkStmtList, n.info)
  var deps = newSeq[(IntSet, IntSet)](n.len)
  for i in 0..<n.len:
    deps[i][0] = initIntSet()
    deps[i][1] = initIntSet()
    computeDeps(n[i], deps[i][0], deps[i][1], true)

  var g = buildGraph(n, deps)
  let comps = getStrongComponents(g)
  mergeSections(comps, result)