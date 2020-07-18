when defined(nimHasUsed): {.used.}

import ast, options, types, msgs, lineinfos, semdata, renderer
from strutils import `%`

proc `$`(a: ViewConstraint): string =
  # result = $a.lhs.owner & "." & $a.lhs & " => " & $a.rhs.owner & "." & $a.rhs & ":" & $a.addrLevel
  proc name2(a: PSym): string = a.owner.name.s & "." & a.name.s
  result = a.lhs.name2 & " => " & a.rhs.name2 & ":" & $a.addrLevel

proc toHuman*(a: seq[ViewConstraint]): string =
  # why is this needed? doesnt' seem to pickup `$`(a: ViewConstraint) otherwise
  for ai in a: result.add $ai & "; "

# IMPROVE RENAME
proc nimToHumanViewConstraint(a: seq[ViewConstraint]): string {.exportc.} = toHuman(a)

type ViewData* = object
  c*: PContext
  lhs*: PSym
  n*: PNode

proc containsView(c: PContext, typ: PType, n: PNode): bool
proc viewFromRoots(result: var ViewData, n: PNode, depth: int, addrLevel: int)

proc resolveParamToPNode(c: PContext, fun: PSym, nCall: PNode, sym: PSym): PNode =
  if sym.kind == skParam:
    if sym.owner == fun:
      result = nCall[1 + sym.position]
      doAssert result != nil

proc resolveSymbolLHS(c: PContext, n, le: PNode): PSym =
  #[
  TODO: also return addrLevel
  we could also return an iterator to handle cases like:
  g(x,y) = fun(a,b,c)
  => yield x, yield y
  ]#
  let typ = le.typ.skipTypes(abstractInst)
  # dbg le.kind, n.renderTree, c.config$n.info, typ.kind
  let ok = containsView(c, le.typ, n)
  # xxx handle this: (x1, x2) = (ptr1, ptr2)
  # dbg ok, le.typ, le.typ.kind
  if ok:
    var ni = le
    while true:
      case ni.kind
      of nkHiddenDeref, nkDerefExpr: ni = ni[0] # eg: var result or var param
      of nkBracketExpr, nkDotExpr, nkCheckedFieldExpr: ni = ni[0]
      of nkCast, nkHiddenStdConv: ni = ni[1]
      of nkSym: return ni.sym
      of nkHiddenAddr: ni = ni[0]
      of nkCallKinds:
        if ni.len >= 2:
          #[
          this happened for: `g.tokens[^1].sym = sym` (^ leads to a function call)
          We could also check all arguments, but for simplicity we for now just
          check the 1st one, see also RFC #7373
          ]#
          ni = ni[1]
      else:
        # TODO
        if ndebugEchoEnabled():
          dbg ni
          dbg2 ni
          doAssert false, $ni.kind
        else:
          break

proc onEscape(vdata: var ViewData, sym: PSym)=
  let frame = sym.owner
  # `vdata.c.p.owner` not as relevant for error message
  message(vdata.c.config, vdata.n.info, warnStackAddrEscapes,
    "local '$1.$2' escapes via '$3' in '$4'" %
      [frame.name.s, sym.name.s, vdata.lhs.name.s, renderTree(vdata.n)])

proc outlivesProcFrame(lhs, rhs: PSym): bool =
  ##[
  return whether `lhs` outlives `rhs`, in which case a warning/error should be issued
  since what lhs points to would be invalidated when rhs dies and lhs outlives it.
  here are just a few examples:
  proc fn(a: int): auto = a.addr # true
  proc fn(a: ptr int): auto = a.addr # true
  proc fn(a: var int): auto = a.addr # false
  proc fn(a: ptr int): auto = a # false

  nesting is small on average so no need to cache some `PSym.depth`.
  ]##
  let lhsFrame=lhs.owner
  var s = rhs.owner
  if s == nil: return false
  if s == lhsFrame:
    if lhs.kind in {skParam, skResult}:
      if rhs.kind notin {skParam, skResult}:
        # eg: proc fn(): auto = (var a = 0; return a.addr)
        return true
      else:
        if rhs.typ.kind == tyVar:
          doAssert false # doesn't fall here; what about tyLent?
          return false 
        else: return true
    else: return false

  if s.kind in {skParam, skResult}: return false
  while true:
    s = s.owner
    if s == nil: return false
    elif s == lhsFrame: return true

proc findScopeDepth(scope: PScope, sym: PSym): int =
  var scope = scope
  while true:
    doAssert scope != nil, $sym
    if sym in scope.symbols.data:
      return scope.depthLevel
    scope = scope.parent

proc outlives(c: PContext, lhs, rhs: PSym): bool =
  # dbg lhs, rhs, lhs.flags, rhs.flags
  # dbg2 lhs
  # dbg2 rhs
  if sfGlobal in lhs.flags: return sfGlobal notin rhs.flags
  if sfGlobal in rhs.flags: return false
  result = outlivesProcFrame(lhs, rhs)
  if not result: # consider block scope
    # TODO: store scope in PSym? or maybe at least depth?
    var scope = c.currentScope
    let d1 = findScopeDepth(scope, lhs)
    let d2 = findScopeDepth(scope, rhs)
    # dbg result, d1, d2, lhs, rhs, lhs.flags, rhs.flags
    if d1 < d2:
      result = true

proc isLocalSymbol(vd: var ViewData, sym: PSym): bool =
  #[
  what if its 2 globals?
  g0=>g1
  ]#
  # PRTEMP
  let funContext = vd.c.p.owner
  result = sfGlobal notin sym.flags and sym.owner == funContext and sym.kind notin {skParam, skResult}
  # checkme: skResult?
  # if sym.owner != funContext or lhs.owner.kind in {skParam, skResult} or sfGlobal in lhs.flags:

proc insertNoDupCheck(result: var ViewData, sym: PSym, addrLevel: int) =
  dbg result.lhs, sym, addrLevel
  let lhs = result.lhs
  if addrLevel == 1 and outlives(result.c, lhs, sym):
    onEscape(result, sym)
  else:
    block:
      # IMPROVE
      var found = false
      for ai in mitems(lhs.viewSyms):
        if sym == ai.sym:
          ai.addrLevel = max(ai.addrLevel, addrLevel)
          found = true
          break
      let fun = lhs.owner
      if fun.kind in routineKinds:
        for ai in mitems(fun.viewConstraints):
          if ai.lhs == lhs and ai.rhs == sym:
            ai.addrLevel = max(ai.addrLevel, addrLevel)
            found = true
            break
      if found:
        return

    let vd = ViewDep(sym: sym, addrLevel: addrLevel)
    # if ever becomes a bottleneck, we could use a Table-like structure (unlikely)
    #[
    D20200713T102518:here to avoid:  the length of the seq changed while iterating over it [AssertionDefect]
    ]#
    # if sym!=lhs:# CHECKME: D20200713T102518
    lhs.viewSyms.add vd
    dbg vd

    # update proc sym
    if lhs.kind in {skParam, skResult}:
      let fun = result.c.p.owner
      # PRTEMP
      # doAssert lhs.owner == fun # TODO: not always holds, see D20200715T004851
      if lhs.owner == fun: # TODO: not always holds, see D20200715T004851
        if lhs.kind == skResult:
          # IMPROVE can we get it from result.c.p ? EDIT: see c.p.resultSym
          fun.resultSym = lhs

    # PRTEMP
    if not isLocalSymbol(result, lhs) and not isLocalSymbol(result, sym):
      let vc = ViewConstraint(lhs: result.lhs, rhs: sym, addrLevel: addrLevel)
      dbg vc
      #[
      note: we don't want to update viewConstraints for symbols that were instantiated
      ]#
      if result.lhs.kind in {skParam}: # {skParam, skResult}
        let fun = result.lhs.owner
        if fun == result.c.p.owner: # checkme
          if vc notin fun.viewConstraints:
            fun.viewConstraints.add vc
            # dbg fun, fun.viewConstraints

      if sym.kind in {skParam}:
        let fun = sym.owner
        if fun == result.c.p.owner: # checkme
          if vc notin fun.viewConstraints:
            fun.viewConstraints.add vc
            # dbg fun, fun.viewConstraints

    # echo ($sym, $result.lhs, $fun, $fun.kind, "D20200715T110042") # PRTEMP 2
      # dbg ($sym, $result.lhs, $fun, $fun.kind, "D20200715T110042") # PRTEMP 2
      # dbg fun
      # if vc notin fun.viewConstraints:
      #   # TODO: find + update if some other vc.addrLevel w same lhs/rhs found
      #   fun.viewConstraints.add vc
      #   dbg fun, fun.viewConstraints

    when false:
      let funContext = result.c.p.owner
      dbg lhs.owner, funContext, lhs.owner.kind
      if lhs.owner != funContext or lhs.owner.kind in {skParam, skResult} or sfGlobal in lhs.flags:
        let vc = ViewConstraint(lhs: result.lhs, rhs: sym, addrLevel: addrLevel)
        dbg vc
        # if sym.kind in {skParam, skResult}:
        if sym.kind in {skParam}:
          let fun = sym.owner
          if fun == funContext: # PRTEMP
            if vc notin fun.viewConstraints:
              # TODO: find + update if some other vc.addrLevel w same lhs/rhs found
              fun.viewConstraints.add vc
              dbg fun, fun.viewConstraints

proc addDependencies(result: var ViewData, sym: PSym, addrLevel: int) =
  #[
  TODO: do we need to take transitive closure at the end
  TODO: instead of making the graph complete, we could at the end do a cycle check / DFS /BFS on a sparse graph?
  ]#
  # dbg result.c.config$result.n.info, result.lhs, sym, sym.viewSyms, addrLevel
  # doAssert addrLevel > -20 # fail early on inf recursion
  if result.lhs == sym: return

  if addrLevel == 1:
    insertNoDupCheck(result, sym, addrLevel)
  elif addrLevel > 1:
    doAssert false, $(addrLevel, sym)
  else:
    #[
    PRTEMP; eg:
    proc fn(a: ptr int): auto = a
    proc fn(a: ptr int): auto =
      var b = a
      result = b
    ]#

    # dbg sym, sym.kind
    if sym.kind in {skParam, skResult}:
      insertNoDupCheck(result, sym, addrLevel)

    # for ai in sym.viewSyms: ? but see D20200713T102518
    let len1 = sym.viewSyms.len
    # dbg sym.viewSyms
    for i in 0..<len1:
      let ai = sym.viewSyms[i]
      var addrLevel2 = addrLevel+ai.addrLevel
      var found = false
      for aj in result.lhs.viewSyms:
        if aj.sym == ai.sym:
          if aj.addrLevel >= addrLevel2:
            found = true # avoid infinite loop D20200713T163711:here
          break
      if not found:
        addDependencies(result, ai.sym, addrLevel2)

proc evalConstraint(c: PContext, fun: PSym, vc: ViewConstraint, nCall: PNode, resultSym: PSym = nil) =
  var lhs = vc.lhs
  if lhs.kind == skResult and lhs.owner == fun:
    doAssert resultSym!=nil
    lhs = resultSym
  else:
    let lhsNode = resolveParamToPNode(c,fun,nCall,lhs)
    # dbg lhs, fun, vc, nCall, lhsNode
    if lhsNode != nil:
      lhs=resolveSymbolLHS(c, nCall, lhsNode)
  if lhs==nil:
    return
  var vdata = ViewData(c: c, lhs: lhs, n: nCall)
  let addrLevel = vc.addrLevel
  var rhs = vc.rhs
  if rhs.kind == skResult and rhs.owner == fun:
    doAssert resultSym!=nil
    #[
    D20200718T125524:here
    checkme: not entirely correct eg:
    proc fn(a: ptr int, b: var ptr int): auto =
      result = a
      b = result
    result = l0.addr
    var b: ptr int
    result = fn(l1.addr, b)
    # b should not depend on l0.addr
    ]#

    rhs = resultSym
  else:
    let rhsNode = resolveParamToPNode(c, fun, nCall, rhs)
    if rhsNode != nil:
      viewFromRoots(vdata, rhsNode, depth=0, addrLevel=addrLevel)
      return
  addDependencies(vdata, rhs, addrLevel)

proc simulateCall(vdata: var ViewData, fun: PSym, nCall: PNode, depth: int, addrLevel: int) =
  # dbg2 fun
  doAssert fun != nil
  if fun.magic == mAddr:  # TODO: do we need this special case?
    # addrLevel.inc # seemed buggy as could apply to unrelated things?
    viewFromRoots(vdata, nCall[1], depth+1, addrLevel + 1)
    return

  if fun.kind notin routineKinds:
    dbg "D20200713T124517", fun.kind
    return
  let ret = fun.resultSym
  if ret == nil:
    #[
    TODO: sfImportc?
    # sfWasForwarded
    the real criterion should be whether it was processed?
    ]#
    if not (sfForward in fun.flags or fun.magic != mNone):
      # eg: `proc fn(): ptr int = discard` ; no `result = ` decl'
      # TODO: instead, assign ret.viewSyms where relevant
      return
    #[
    `fun` has not body (eg it's a magic or forward decl)
    TODO: shd use {.viewFrom.} if available
    eg: `@` (mArrToSeq)
    proc `@`* [IDX, T](a: sink array[IDX, T]): seq[T] {.magic: "ArrToSeq", noSideEffect.}
    TODO: what about sink params?
    ]#
    for i in 1..<nCall.len:
      # CHECKME
      viewFromRoots(vdata, nCall[i], depth+1, addrLevel)
    return

  #[
  D20200716T235232:here
  # for ai in ret.viewSyms:
  the length of the seq changed while iterating over it
  can happen for recursive calls, eg:
  proc genTypeInfo(m: BModule, t: PType; info: TLineInfo): Rope =
      if t.n != nil: result = genTypeInfo(m, lastSon t, info)
  ]#
  when false:
    block:
      var index = 0
      while true:
        if index>=ret.viewSyms.len: break
        let ai = ret.viewSyms[index]
        index.inc
        # dbg ai, "begin", ret.viewSyms
        # TODO: for params, avoid
        var sym = ai.sym
        # dbg ai, addrLevel, addrLevel + ai.addrLevel
        var addrLevel2 = addrLevel + ai.addrLevel

        # FACTOR with evalConstraint
        let rhsNode = resolveParamToPNode(vdata.c,fun,nCall,sym)
        if rhsNode!=nil:
          viewFromRoots(vdata, rhsNode, depth+1, addrLevel2)
        else:
          addDependencies(vdata, sym, addrLevel2)
        # dbg ai, "end", ret.viewSyms, fun, vdata.c.config$fun.info

  # eval other constraints; FACTOR
  # for vc in fun.viewConstraints:
  block:
    var index = 0
    while true:
      if index>=fun.viewConstraints.len: break
      let vc = fun.viewConstraints[index]
      index.inc
      # dbg vc, ret, fun
      # if vc.lhs != ret:
      #   # TODO: merge previous section to here
      #   evalConstraint(vdata.c, fun, vc, nCall, vdata.lhs)
      evalConstraint(vdata.c, fun, vc, nCall, vdata.lhs)

proc viewFromRoots(result: var ViewData, n: PNode, depth: int, addrLevel: int) =
  var addrLevel = addrLevel # `sfAddrTaken` is inadequate (depends on unrelated context)
  # dbg result.n.renderTree, depth, n.renderTree, n.kind, addrLevel, result.c.config$n.info
  var it = n
  template continueSon(index, expectedLen) =
    doAssert it.len == expectedLen
    it = it[index]
  template recurseSons(first) =
    for i in first..<it.len:
      # could avoid recursion using stack...
      viewFromRoots(result, it[i], depth+1, addrLevel)
    break

  while true:
    # dbg it.kind, it.renderTree
    case it.kind
    of nkSym:
      # dbg sym, addrLevel, sfAddrTaken in sym.flags, result.lhs, sym.viewFromSyms
      addDependencies(result, it.sym, addrLevel)
      break
    of nkHiddenDeref, nkDerefExpr:
      # can go negative, eg: var l1=a.addr; result = l1[]
      addrLevel.dec
      #[
      but we can now make the escape analysis correct instead of previous behavior:
      in some other parts of the code, we had this:
        if it[0].typ.skipTypes(abstractInst).kind in {tyPtr, tyRef}: break
          # 'ptr' is unsafe anyway and 'ref' is always on the heap [...]
      ]#
      continueSon(0, 1)
    of nkBracketExpr:
      # addresses are on heap for seq, but watch out for cases like: `var a: seq[ptr int]`
      let n2 = it[0]
      let t2 = n2.typ
      case t2.kind
      of tySequence, tyCString, tyString:
        # tyString should probably not hit here since string content is allocated on heap but still
        addrLevel.dec
        # discard # PRTEMP
      of tyArray, tyTuple, tyUncheckedArray, tyOpenArray,
        tyGenericInst, # D20200711T222510 eg: `t.data[index]` with t.data a tyGenericInst
        tyVarargs:
        discard # addrLevel.dec would be incorrect: `a` and `a[0]` are at same address (or address "level")
      else:
        dbg2 n
        dbg2 it
        dbg2 t2
        doAssert false, $("not yet implemented", t2.kind) # if fails, adapt code as needed
      it = it[0]
    of nkDotExpr, nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr: continueSon(0, 2)
    of nkHiddenStdConv, nkHiddenSubConv, nkConv: continueSon(1, 2)
    of nkStmtList, nkStmtListExpr:
      if it.len > 0 and it.typ != nil: it = it.lastSon
      else: break
    of nkHiddenAddr: # eg: `proc fn(a: var int); fn(a0)`
      addrLevel.inc
      continueSon(0, 1)
    of nkCallKinds:
      when false:
        #[
        See RFC #7373, calls returning 'var T' are assumed to return a view into the first argument (if there is one):
        if root.kind in {skLet, skVar, skTemp} and sfGlobal notin root.flags: bad1
        elif root.kind == skParam and root.position != 0: bad2
        ]#
        if it.typ != nil and it.typ.kind in {tyVar, tyLent} and it.len > 1: it = it[1]
        else: break

      let fun = it[0]
      if fun.kind == nkSym: # else eg: let z = mt.base.deepcopy(s2) # TODO: find the sym in this case?
        # TODO: use nimSimulateCall?
        simulateCall(result, fun.sym, it, depth, addrLevel)
        break
      else:
        # eg: cast[PPointer](dest)[]
        dbg "D20200712T195444", fun.kind # TODO
        recurseSons(1)
    of nkTupleConstr, nkBracket: recurseSons(0)
    of nkBlockExpr: it = it[^1]
    of nkObjConstr: recurseSons(1)
    of nkExprColonExpr: continueSon(1, 2) # TODO: only if it's a ptr-like type?
    of {nkEmpty, nkNilLit} + {nkCharLit..nkFloat128Lit}: break
    of nkCast: continueSon(1, 2) # eg: cast[cstring](a[0].addr)
    of nkIfExpr: recurseSons(0)
    of nkElifExpr: continueSon(1, 2)
    of nkElseExpr: continueSon(0, 1)
    of nkStrLit..nkTripleStrLit:
      #[
      var a = "abc".cstring # allocated in static data segment, not on stack
      var b = cast[cstring](a[0].addr) # ok to escape

      Note: we could extend this logic to track memory originating from static data segment,
      eg to avoid SIGBUS see https://github.com/timotheecour/Nim/issues/85
      as well as enable things like D's static const to implement default values
      for objects in the general case.
      see https://github.com/nim-lang/RFCs/issues/126#issuecomment-616306221
      ]#
      break
    else:
      dbg it.kind, it.safeLen, it.renderTree, result.c.config$n.info
      break

proc skipToSym(n: PNode): PType =
  if n.kind == nkRecList:
    if n.sons.len == 0: return nil # eg: `of rkNone: nil`
    else: return n[0].sym.typ # D20200711T105926 pending bug #14966
  elif n.kind == nkSym: return n.sym.typ
  else: doAssert false, $n.kind

proc containsView(c: PContext, typ: PType, n: PNode): bool =
  #[
  potentially relevant: `tfHasGCedMem in typ.flags`
  ]#
  var t = typ.skipTypes(abstractInst)

  template fun(tj) =
    if containsView(c, tj, n): return true

  template visitSimple(tparent) =
    for i in 0..<tparent.len: fun(tparent[i])
    break

  template visitObj(tparent) =
    for i in 0..<tparent.len:
      let ni = tparent[i]
      case ni.kind
      of nkRecCase: # hack for simplicity; maybe we could use an iterator
        for j in 1..<ni.len:
          let nj = ni[j][^1]
          let tj = nj.skipToSym
          if tj != nil: fun(tj)
      else: fun(skipToSym(ni))
    break

  while true:
    case t.kind
    of tyPtr, tyRef, tyPointer:
      result = true # TODO: for tyRef, we probably should recurse before deciding, eg: `ref int`
      break
    of tyCString:
      #[
      D20200710T213712
      ]#
      result = true
      break
    of tyVar:
      # TODO: this depends whether it's lhs or rhs; for rhs, it'd be true; for rhs, it'd be t=t[0]
      # t = t[0]
      result = true
      break
    of tyArray: t = t[1]
    of tySequence: t = t[0]
    of tyDistinct, tyAlias: t = t[0]
    of tyObject:
      # checkme: how come t.sons is empty?
      visitObj(t.n.sons)
    of tyGenericInst: visitObj(t[^1].n.sons)
    of tyTuple: visitSimple(t)
    of tyInt..tyUInt64, tyBool, tyChar, tyEnum: break
    of tyString, tySet, tyRange: break # CHECKME; because string elements are on heap; but is that correct? eg for `proc fn(a: var string)`?
    of tyProc:
      #[
      checkme D20200710T211322
      would that change under https://github.com/nim-lang/Nim/pull/14881 ?
      allocate closure env on stack if viable (wip)
      ]#
      break
    else:
      dbg t, t.kind
      if ndebugEchoEnabled():
        dbg2 t
        doAssert false, $("not yet implemented", t.kind, typ.kind, c.config$n.info, n.renderTree)
      break

proc nimCheckViewFromCompat*(c: PContext, n, le, ri: PNode) {.exportc, dynlib.} =
  # if optStaticEscapeCheck notin c.config.options: return
  if staticEscapeChecks notin c.features: return
  if ri.kind in {nkEmpty, nkNilLit}: return # eg: var a: int
  let lhs = resolveSymbolLHS(c, n, le)
  if lhs != nil:
    var viewData = ViewData(c: c, lhs: lhs, n: n)
    viewFromRoots(viewData, ri, 0, 0)

# when defined(timn_define_lib):
when true:
  proc nimSimulateCall(c: PContext, fun: PSym, nCall: PNode) {.exportc, dynlib.} =
    # if optStaticEscapeCheck notin c.config.options: return
    if staticEscapeChecks notin c.features: return
    case fun.kind
    of skVar, skLet, skIterator, skParam:
      #[
      TODO: skVar; fun: errorMessageWriter@3870604;
      TODO: handle skIterator

      skLet:
      let marker = cell.typ.marker
      marker(cellToUsr(cell), op.int)
      
      skParam:
      proc translate*(s: string, replacements: proc(key: string): string): string {.
      result.add(replacements(word))
      ]#
      discard
    of skProc, skFunc: # TOOD: routineKinds
      # dbg fun.resultSym
      # if fun.resultSym != nil: return # CHECKME; will be taken care by 
      if fun.typ[0] != nil: return # CHECKME; will be taken care by nimCheckViewFromCompat; BUT should relax the `containsView` check to cover it
      # dbg c.config$nCall.info, nCall.renderTree, fun, c.config$fun.ast.info, fun.viewConstraints
      # let num0 = fun.viewConstraints.len

      # for recursive calls eg: processQuotations
      # for vc in fun.viewConstraints:
      var index = 0
      while true:
        if index >= fun.viewConstraints.len: break
        let vc = fun.viewConstraints[index]
        index.inc
        # TODO: avoid updating `viewConstraints` inside this?
        # var old = fun.viewConstraints
        evalConstraint(c, fun, vc, nCall)
        when false:
          if fun.viewConstraints.len != num0:
            dbg c.p.owner, fun, nCall.renderTree, "\n", $fun.viewConstraints, "\n", $old
            # dbg fun.viewConstraints, fun, nCall.renderTree
            #[
            processQuotations
            ]#
            doAssert false
    else:
      dbg fun.kind, fun
      doAssert false

  # proc timnEchoEnabled(): bool {.exportc.} = true # PRTEMP

# else:
#   proc nimSimulateCall(c: PContext, fun: PSym, nCall: PNode) {.cdecl, importc, dynlib: "/tmp/libz09x.dylib".}

# PRTEMP incremental D20200712T171305
# import ./debugutils
# when true:
when false:
# when defined(timn_with_compilerutils):
  # import timn/compilerutils/nimc_basics
  # import timn/compilerutils/nimc_interface2
  # proc timnEchoEnabled(): bool {.exportc.} = true # PRTEMP
  discard
