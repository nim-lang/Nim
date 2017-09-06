
import intsets, tables, ast, idents, renderer, algorithm

type
  DepNode = ref object
    id, index, lowLink: int
    onStack: bool
    kids: seq[DepNode]
  DepGraph = seq[DepNode]

# to do: rename DepNode and DepGraph with respect to conventions
proc newDepNode(id: int): DepNode =
  new(result)
  result.id = id
  result.index = -1
  result.lowLink = -1
  result.onStack = false
  result.kids = @[]

proc buildGraph(deps: seq[(IntSet, IntSet)]): DepGraph =
  result = newSeqOfCap[DepNode](deps.len)
  for i in 0..<deps.len:
    result.add newDepNode(i)
  for i in 0..<deps.len:
    var n = result[i]
    let declares = deps[i][0]
    for j in 0..<deps.len:
      if i == j: continue
      let uses = deps[j][1]
      for d in declares:
        if uses.contains(d):
          n.kids.add result[j]

#to do: ident
proc strongConnect(v: var DepNode, index: var int, s: var seq[DepNode], comps: var seq[seq[DepNode]]) =
  v.index = index
  v.lowLink = index
  inc index
  s.add v
  v.onStack = true
  for w in v.kids.mitems:
    if w.index < 0:
      strongConnect(w, index, s, comps)
      v.lowLink = min(v.lowLink, w.lowLink)
    elif w.onStack:
      v.lowLink = min(v.lowLink, w.index)
  if v.lowLink == v.index:
    var comp = newSeq[DepNode]()
    while true:
      var w = s.pop
      w.onStack = false
      comp.add w
      if w.id == v.id: break
    comps.add comp.reversed

proc getStrongComponents(g: var DepGraph): seq[seq[DepNode]] =
  ## Tarjan's strongly connected components algorithm
  result = newSeq[seq[DepNode]]()
  var s = newSeq[DepNode]()
  var index = 0
  for v in g.mitems:
    if v.index < 0:
      strongConnect(v, index, s, result)
  result.reverse

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

proc haveSameKind(n: PNode, dns: seq[DepNode]): bool =
  result = true
  let kind = n.sons[dns[0].id].kind
  for dn in dns:
    if n.sons[dn.id].kind != kind:
      return false
    

proc reorder*(n: PNode): PNode =
  template node(dn): PNode = n.sons[dn.id]
  let n = splitSections(n)
  result = newNodeI(nkStmtList, n.info)
  var deps = newSeq[(IntSet, IntSet)](n.len)
  for i in 0..<n.len:
    deps[i][0] = initIntSet()
    deps[i][1] = initIntSet()
    computeDeps(n[i], deps[i][0], deps[i][1], true)

  var g = buildGraph(deps)
  let comps = getStrongComponents(g)
  echo n.len
  echo comps.len
  for a in comps:
    # echo "------------------"
    # for b in a:
    #   echo b.id
    if a.len > 0:
      echo "**********************************************"
      for b in a:
        let uses = deps[b.id][1]
        let declares = deps[b.id][0]
        echo "id = " & $b.id
        echo "uses = " & $uses
        echo "declares = " & $declares
        echo n.sons[b.id]
        echo "-----------------------------------------"

  for c in comps:
    assert c.len > 0
    if c.len == 1:
      result.add node(c[0])
    else:
      let fstn = n.sons[c[0].id]
      let kind = fstn.kind
      if kind in {nkTypeSection, nkConstSection} and haveSameKind(n, c):
        var sn = newNode(kind)
        for dn in c:
          sn.add node(dn).sons[0]
        result.add sn
      else:
        for dn in c:
          result.add node(dn)