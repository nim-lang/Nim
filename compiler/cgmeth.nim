#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements code generation for multi methods.

import
  intsets, options, ast, astalgo, msgs, idents, renderer, types, magicsys,
  sempass2, strutils, modulegraphs, lineinfos

proc genConv(n: PNode, d: PType, downcast: bool; conf: ConfigRef): PNode =
  var dest = skipTypes(d, abstractPtrs)
  var source = skipTypes(n.typ, abstractPtrs)
  if (source.kind == tyObject) and (dest.kind == tyObject):
    var diff = inheritanceDiff(dest, source)
    if diff == high(int):
      # no subtype relation, nothing to do
      result = n
    elif diff < 0:
      result = newNodeIT(nkObjUpConv, n.info, d)
      addSon(result, n)
      if downcast: internalError(conf, n.info, "cgmeth.genConv: no upcast allowed")
    elif diff > 0:
      result = newNodeIT(nkObjDownConv, n.info, d)
      addSon(result, n)
      if not downcast:
        internalError(conf, n.info, "cgmeth.genConv: no downcast allowed")
    else:
      result = n
  else:
    result = n

proc getDispatcher*(s: PSym): PSym =
  ## can return nil if is has no dispatcher.
  if dispatcherPos < s.ast.len:
    result = s.ast[dispatcherPos].sym
    doAssert sfDispatcher in result.flags

proc methodCall*(n: PNode; conf: ConfigRef): PNode =
  result = n
  # replace ordinary method by dispatcher method:
  let disp = getDispatcher(result.sons[0].sym)
  if disp != nil:
    result.sons[0].sym = disp
    # change the arguments to up/downcasts to fit the dispatcher's parameters:
    for i in countup(1, sonsLen(result)-1):
      result.sons[i] = genConv(result.sons[i], disp.typ.sons[i], true, conf)
  else:
    localError(conf, n.info, "'" & $result.sons[0] & "' lacks a dispatcher")

type
  MethodResult = enum No, Invalid, Yes

proc sameMethodBucket(a, b: PSym): MethodResult =
  if a.name.id != b.name.id: return
  if sonsLen(a.typ) != sonsLen(b.typ):
    return

  for i in countup(1, sonsLen(a.typ) - 1):
    var aa = a.typ.sons[i]
    var bb = b.typ.sons[i]
    while true:
      aa = skipTypes(aa, {tyGenericInst, tyAlias})
      bb = skipTypes(bb, {tyGenericInst, tyAlias})
      if aa.kind == bb.kind and aa.kind in {tyVar, tyPtr, tyRef, tyLent}:
        aa = aa.lastSon
        bb = bb.lastSon
      else:
        break
    if sameType(a.typ.sons[i], b.typ.sons[i]):
      if aa.kind == tyObject and result != Invalid:
        result = Yes
    elif aa.kind == tyObject and bb.kind == tyObject:
      let diff = inheritanceDiff(bb, aa)
      if diff < 0:
        if result != Invalid:
          result = Yes
        else:
          return No
      elif diff != high(int) and sfFromGeneric notin (a.flags+b.flags):
        result = Invalid
      else:
        return No
    else:
      return No
  if result == Yes:
    # check for return type:
    if not sameTypeOrNil(a.typ.sons[0], b.typ.sons[0]):
      if b.typ.sons[0] != nil and b.typ.sons[0].kind == tyExpr:
        # infer 'auto' from the base to make it consistent:
        b.typ.sons[0] = a.typ.sons[0]
      else:
        return No

proc attachDispatcher(s: PSym, dispatcher: PNode) =
  if dispatcherPos < s.ast.len:
    # we've added a dispatcher already, so overwrite it
    s.ast.sons[dispatcherPos] = dispatcher
  else:
    setLen(s.ast.sons, dispatcherPos+1)
    if s.ast[resultPos] == nil:
      s.ast[resultPos] = newNodeI(nkEmpty, s.info)
    s.ast.sons[dispatcherPos] = dispatcher

proc createDispatcher(s: PSym): PSym =
  var disp = copySym(s)
  incl(disp.flags, sfDispatcher)
  excl(disp.flags, sfExported)
  disp.typ = copyType(disp.typ, disp.typ.owner, false)
  # we can't inline the dispatcher itself (for now):
  if disp.typ.callConv == ccInline: disp.typ.callConv = ccDefault
  disp.ast = copyTree(s.ast)
  disp.ast.sons[bodyPos] = newNodeI(nkEmpty, s.info)
  disp.loc.r = nil
  if s.typ.sons[0] != nil:
    if disp.ast.sonsLen > resultPos:
      disp.ast.sons[resultPos].sym = copySym(s.ast.sons[resultPos].sym)
    else:
      # We've encountered a method prototype without a filled-in
      # resultPos slot. We put a placeholder in there that will
      # be updated in fixupDispatcher().
      disp.ast.addSon(newNodeI(nkEmpty, s.info))
  attachDispatcher(s, newSymNode(disp))
  # attach to itself to prevent bugs:
  attachDispatcher(disp, newSymNode(disp))
  return disp

proc fixupDispatcher(meth, disp: PSym; conf: ConfigRef) =
  # We may have constructed the dispatcher from a method prototype
  # and need to augment the incomplete dispatcher with information
  # from later definitions, particularly the resultPos slot. Also,
  # the lock level of the dispatcher needs to be updated/checked
  # against that of the method.
  if disp.ast.sonsLen > resultPos and meth.ast.sonsLen > resultPos and
     disp.ast.sons[resultPos].kind == nkEmpty:
    disp.ast.sons[resultPos] = copyTree(meth.ast.sons[resultPos])

  # The following code works only with lock levels, so we disable
  # it when they're not available.
  when declared(TLockLevel):
    proc `<`(a, b: TLockLevel): bool {.borrow.}
    proc `==`(a, b: TLockLevel): bool {.borrow.}
    if disp.typ.lockLevel == UnspecifiedLockLevel:
      disp.typ.lockLevel = meth.typ.lockLevel
    elif meth.typ.lockLevel != UnspecifiedLockLevel and
         meth.typ.lockLevel != disp.typ.lockLevel:
      message(conf, meth.info, warnLockLevel,
        "method has lock level $1, but another method has $2" %
        [$meth.typ.lockLevel, $disp.typ.lockLevel])
      # XXX The following code silences a duplicate warning in
      # checkMethodeffects() in sempass2.nim for now.
      if disp.typ.lockLevel < meth.typ.lockLevel:
        disp.typ.lockLevel = meth.typ.lockLevel

proc methodDef*(g: ModuleGraph; s: PSym, fromCache: bool) =
  let L = len(g.methods)
  var witness: PSym
  for i in countup(0, L - 1):
    let disp = g.methods[i].dispatcher
    case sameMethodBucket(disp, s)
    of Yes:
      add(g.methods[i].methods, s)
      attachDispatcher(s, disp.ast[dispatcherPos])
      fixupDispatcher(s, disp, g.config)
      #echo "fixup ", disp.name.s, " ", disp.id
      when useEffectSystem: checkMethodEffects(g, disp, s)
      if {sfBase, sfFromGeneric} * s.flags == {sfBase} and
           g.methods[i].methods[0] != s:
        # already exists due to forwarding definition?
        localError(g.config, s.info, "method is not a base")
      return
    of No: discard
    of Invalid:
      if witness.isNil: witness = g.methods[i].methods[0]
  # create a new dispatcher:
  add(g.methods, (methods: @[s], dispatcher: createDispatcher(s)))
  #echo "adding ", s.info
  #if fromCache:
  #  internalError(s.info, "no method dispatcher found")
  if witness != nil:
    localError(g.config, s.info, "invalid declaration order; cannot attach '" & s.name.s &
                       "' to method defined here: " & g.config$witness.info)
  elif sfBase notin s.flags:
    message(g.config, s.info, warnUseBase)

proc relevantCol(methods: seq[PSym], col: int): bool =
  # returns true iff the position is relevant
  var t = methods[0].typ.sons[col].skipTypes(skipPtrs)
  if t.kind == tyObject:
    for i in countup(1, high(methods)):
      let t2 = skipTypes(methods[i].typ.sons[col], skipPtrs)
      if not sameType(t2, t):
        return true

proc cmpSignatures(a, b: PSym, relevantCols: IntSet): int =
  for col in countup(1, sonsLen(a.typ) - 1):
    if contains(relevantCols, col):
      var aa = skipTypes(a.typ.sons[col], skipPtrs)
      var bb = skipTypes(b.typ.sons[col], skipPtrs)
      var d = inheritanceDiff(aa, bb)
      if (d != high(int)) and d != 0:
        return d

proc sortBucket(a: var seq[PSym], relevantCols: IntSet) =
  # we use shellsort here; fast and simple
  var n = len(a)
  var h = 1
  while true:
    h = 3 * h + 1
    if h > n: break
  while true:
    h = h div 3
    for i in countup(h, n - 1):
      var v = a[i]
      var j = i
      while cmpSignatures(a[j - h], v, relevantCols) >= 0:
        a[j] = a[j - h]
        j = j - h
        if j < h: break
      a[j] = v
    if h == 1: break

proc genDispatcher(g: ModuleGraph; methods: seq[PSym], relevantCols: IntSet): PSym =
  var base = methods[0].ast[dispatcherPos].sym
  result = base
  var paramLen = sonsLen(base.typ)
  var nilchecks = newNodeI(nkStmtList, base.info)
  var disp = newNodeI(nkIfStmt, base.info)
  var ands = getSysMagic(g, unknownLineInfo(), "and", mAnd)
  var iss = getSysMagic(g, unknownLineInfo(), "of", mOf)
  let boolType = getSysType(g, unknownLineInfo(), tyBool)
  for col in countup(1, paramLen - 1):
    if contains(relevantCols, col):
      let param = base.typ.n.sons[col].sym
      if param.typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
        addSon(nilchecks, newTree(nkCall,
            newSymNode(getCompilerProc(g, "chckNilDisp")), newSymNode(param)))
  for meth in countup(0, high(methods)):
    var curr = methods[meth]      # generate condition:
    var cond: PNode = nil
    for col in countup(1, paramLen - 1):
      if contains(relevantCols, col):
        var isn = newNodeIT(nkCall, base.info, boolType)
        addSon(isn, newSymNode(iss))
        let param = base.typ.n.sons[col].sym
        addSon(isn, newSymNode(param))
        addSon(isn, newNodeIT(nkType, base.info, curr.typ.sons[col]))
        if cond != nil:
          var a = newNodeIT(nkCall, base.info, boolType)
          addSon(a, newSymNode(ands))
          addSon(a, cond)
          addSon(a, isn)
          cond = a
        else:
          cond = isn
    let retTyp = base.typ.sons[0]
    let call = newNodeIT(nkCall, base.info, retTyp)
    addSon(call, newSymNode(curr))
    for col in countup(1, paramLen - 1):
      addSon(call, genConv(newSymNode(base.typ.n.sons[col].sym),
                           curr.typ.sons[col], false, g.config))
    var ret: PNode
    if retTyp != nil:
      var a = newNodeI(nkFastAsgn, base.info)
      addSon(a, newSymNode(base.ast.sons[resultPos].sym))
      addSon(a, call)
      ret = newNodeI(nkReturnStmt, base.info)
      addSon(ret, a)
    else:
      ret = call
    if cond != nil:
      var a = newNodeI(nkElifBranch, base.info)
      addSon(a, cond)
      addSon(a, ret)
      addSon(disp, a)
    else:
      disp = ret
  nilchecks.add disp
  nilchecks.flags.incl nfTransf # should not be further transformed
  result.ast.sons[bodyPos] = nilchecks

proc generateMethodDispatchers*(g: ModuleGraph): PNode =
  result = newNode(nkStmtList)
  for bucket in countup(0, len(g.methods) - 1):
    var relevantCols = initIntSet()
    for col in countup(1, sonsLen(g.methods[bucket].methods[0].typ) - 1):
      if relevantCol(g.methods[bucket].methods, col): incl(relevantCols, col)
      if optMultiMethods notin g.config.globalOptions:
        # if multi-methods are not enabled, we are interested only in the first field
        break
    sortBucket(g.methods[bucket].methods, relevantCols)
    addSon(result,
           newSymNode(genDispatcher(g, g.methods[bucket].methods, relevantCols)))
