#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements code generation for methods.

import
  intsets, options, ast, msgs, idents, renderer, types, magicsys,
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
      result.add n
      if downcast: internalError(conf, n.info, "cgmeth.genConv: no upcast allowed")
    elif diff > 0:
      result = newNodeIT(nkObjDownConv, n.info, d)
      result.add n
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
  let disp = getDispatcher(result[0].sym)
  if disp != nil:
    result[0].typ = disp.typ
    result[0].sym = disp
    # change the arguments to up/downcasts to fit the dispatcher's parameters:
    for i in 1..<result.len:
      result[i] = genConv(result[i], disp.typ[i], true, conf)
  else:
    localError(conf, n.info, "'" & $result[0] & "' lacks a dispatcher")

type
  MethodResult = enum No, Invalid, Yes

proc sameMethodBucket(a, b: PSym; multiMethods: bool): MethodResult =
  if a.name.id != b.name.id: return
  if a.typ.len != b.typ.len:
    return

  for i in 1..<a.typ.len:
    var aa = a.typ[i]
    var bb = b.typ[i]
    while true:
      aa = skipTypes(aa, {tyGenericInst, tyAlias})
      bb = skipTypes(bb, {tyGenericInst, tyAlias})
      if aa.kind == bb.kind and aa.kind in {tyVar, tyPtr, tyRef, tyLent, tySink}:
        aa = aa.lastSon
        bb = bb.lastSon
      else:
        break
    if sameType(a.typ[i], b.typ[i]):
      if aa.kind == tyObject and result != Invalid:
        result = Yes
    elif aa.kind == tyObject and bb.kind == tyObject and (i == 1 or multiMethods):
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
    if not sameTypeOrNil(a.typ[0], b.typ[0]):
      if b.typ[0] != nil and b.typ[0].kind == tyUntyped:
        # infer 'auto' from the base to make it consistent:
        b.typ[0] = a.typ[0]
      else:
        return No

proc attachDispatcher(s: PSym, dispatcher: PNode) =
  if dispatcherPos < s.ast.len:
    # we've added a dispatcher already, so overwrite it
    s.ast[dispatcherPos] = dispatcher
  else:
    setLen(s.ast.sons, dispatcherPos+1)
    if s.ast[resultPos] == nil:
      s.ast[resultPos] = newNodeI(nkEmpty, s.info)
    s.ast[dispatcherPos] = dispatcher

proc createDispatcher(s: PSym; g: ModuleGraph; idgen: IdGenerator): PSym =
  var disp = copySym(s, nextSymId(idgen))
  incl(disp.flags, sfDispatcher)
  excl(disp.flags, sfExported)
  let old = disp.typ
  disp.typ = copyType(disp.typ, nextTypeId(idgen), disp.typ.owner)
  copyTypeProps(g, idgen.module, disp.typ, old)

  # we can't inline the dispatcher itself (for now):
  if disp.typ.callConv == ccInline: disp.typ.callConv = ccNimCall
  disp.ast = copyTree(s.ast)
  disp.ast[bodyPos] = newNodeI(nkEmpty, s.info)
  disp.loc.r = nil
  if s.typ[0] != nil:
    if disp.ast.len > resultPos:
      disp.ast[resultPos].sym = copySym(s.ast[resultPos].sym, nextSymId(idgen))
    else:
      # We've encountered a method prototype without a filled-in
      # resultPos slot. We put a placeholder in there that will
      # be updated in fixupDispatcher().
      disp.ast.add newNodeI(nkEmpty, s.info)
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
  if disp.ast.len > resultPos and meth.ast.len > resultPos and
     disp.ast[resultPos].kind == nkEmpty:
    disp.ast[resultPos] = copyTree(meth.ast[resultPos])

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

proc methodDef*(g: ModuleGraph; idgen: IdGenerator; s: PSym) =
  var witness: PSym
  for i in 0..<g.methods.len:
    let disp = g.methods[i].dispatcher
    case sameMethodBucket(disp, s, multimethods = optMultiMethods in g.config.globalOptions)
    of Yes:
      g.methods[i].methods.add(s)
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
  g.methods.add((methods: @[s], dispatcher: createDispatcher(s, g, idgen)))
  #echo "adding ", s.info
  if witness != nil:
    localError(g.config, s.info, "invalid declaration order; cannot attach '" & s.name.s &
                       "' to method defined here: " & g.config$witness.info)
  elif sfBase notin s.flags:
    message(g.config, s.info, warnUseBase)

proc relevantCol(methods: seq[PSym], col: int): bool =
  # returns true iff the position is relevant
  var t = methods[0].typ[col].skipTypes(skipPtrs)
  if t.kind == tyObject:
    for i in 1..high(methods):
      let t2 = skipTypes(methods[i].typ[col], skipPtrs)
      if not sameType(t2, t):
        return true

proc cmpSignatures(a, b: PSym, relevantCols: IntSet): int =
  for col in 1..<a.typ.len:
    if contains(relevantCols, col):
      var aa = skipTypes(a.typ[col], skipPtrs)
      var bb = skipTypes(b.typ[col], skipPtrs)
      var d = inheritanceDiff(aa, bb)
      if (d != high(int)) and d != 0:
        return d

proc sortBucket(a: var seq[PSym], relevantCols: IntSet) =
  # we use shellsort here; fast and simple
  var n = a.len
  var h = 1
  while true:
    h = 3 * h + 1
    if h > n: break
  while true:
    h = h div 3
    for i in h..<n:
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
  var paramLen = base.typ.len
  var nilchecks = newNodeI(nkStmtList, base.info)
  var disp = newNodeI(nkIfStmt, base.info)
  var ands = getSysMagic(g, unknownLineInfo, "and", mAnd)
  var iss = getSysMagic(g, unknownLineInfo, "of", mOf)
  let boolType = getSysType(g, unknownLineInfo, tyBool)
  for col in 1..<paramLen:
    if contains(relevantCols, col):
      let param = base.typ.n[col].sym
      if param.typ.skipTypes(abstractInst).kind in {tyRef, tyPtr}:
        nilchecks.add newTree(nkCall,
            newSymNode(getCompilerProc(g, "chckNilDisp")), newSymNode(param))
  for meth in 0..high(methods):
    var curr = methods[meth]      # generate condition:
    var cond: PNode = nil
    for col in 1..<paramLen:
      if contains(relevantCols, col):
        var isn = newNodeIT(nkCall, base.info, boolType)
        isn.add newSymNode(iss)
        let param = base.typ.n[col].sym
        isn.add newSymNode(param)
        isn.add newNodeIT(nkType, base.info, curr.typ[col])
        if cond != nil:
          var a = newNodeIT(nkCall, base.info, boolType)
          a.add newSymNode(ands)
          a.add cond
          a.add isn
          cond = a
        else:
          cond = isn
    let retTyp = base.typ[0]
    let call = newNodeIT(nkCall, base.info, retTyp)
    call.add newSymNode(curr)
    for col in 1..<paramLen:
      call.add genConv(newSymNode(base.typ.n[col].sym),
                           curr.typ[col], false, g.config)
    var ret: PNode
    if retTyp != nil:
      var a = newNodeI(nkFastAsgn, base.info)
      a.add newSymNode(base.ast[resultPos].sym)
      a.add call
      ret = newNodeI(nkReturnStmt, base.info)
      ret.add a
    else:
      ret = call
    if cond != nil:
      var a = newNodeI(nkElifBranch, base.info)
      a.add cond
      a.add ret
      disp.add a
    else:
      disp = ret
  nilchecks.add disp
  nilchecks.flags.incl nfTransf # should not be further transformed
  result.ast[bodyPos] = nilchecks

proc generateMethodDispatchers*(g: ModuleGraph): PNode =
  result = newNode(nkStmtList)
  for bucket in 0..<g.methods.len:
    var relevantCols = initIntSet()
    for col in 1..<g.methods[bucket].methods[0].typ.len:
      if relevantCol(g.methods[bucket].methods, col): incl(relevantCols, col)
      if optMultiMethods notin g.config.globalOptions:
        # if multi-methods are not enabled, we are interested only in the first field
        break
    sortBucket(g.methods[bucket].methods, relevantCols)
    result.add newSymNode(genDispatcher(g, g.methods[bucket].methods, relevantCols))
