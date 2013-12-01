#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## this module does the semantic checking of statements
#  included from sem.nim

var EnforceVoidContext = PType(kind: tyStmt)

proc semCommand(c: PContext, n: PNode): PNode =
  result = semExprNoType(c, n)
  
proc semDiscard(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty:
    n.sons[0] = semExprWithType(c, n.sons[0])
    if isEmptyType(n.sons[0].typ): localError(n.info, errInvalidDiscard)
  
proc semBreakOrContinue(c: PContext, n: PNode): PNode =
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty: 
    var s: PSym
    case n.sons[0].kind
    of nkIdent: s = lookUp(c, n.sons[0])
    of nkSym: s = n.sons[0].sym
    else: illFormedAst(n)
    if s.kind == skLabel and s.owner.id == c.p.owner.id: 
      var x = newSymNode(s)
      x.info = n.info
      incl(s.flags, sfUsed)
      n.sons[0] = x
      suggestSym(x, s)
    else:
      localError(n.info, errInvalidControlFlowX, s.name.s)
  elif (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0): 
    localError(n.info, errInvalidControlFlowX, 
               renderTree(n, {renderNoComments}))

proc semAsm(con: PContext, n: PNode): PNode = 
  checkSonsLen(n, 2)
  var marker = pragmaAsm(con, n.sons[0])
  if marker == '\0': marker = '`' # default marker
  result = semAsmOrEmit(con, n, marker)
  
proc semWhile(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 2)
  openScope(c)
  n.sons[0] = forceBool(c, semExprWithType(c, n.sons[0]))
  inc(c.p.nestedLoopCounter)
  n.sons[1] = semStmt(c, n.sons[1])
  dec(c.p.nestedLoopCounter)
  closeScope(c)
  if n.sons[1].typ == EnforceVoidContext:
    result.typ = EnforceVoidContext

proc toCover(t: PType): biggestInt = 
  var t2 = skipTypes(t, abstractVarRange-{tyTypeDesc})
  if t2.kind == tyEnum and enumHasHoles(t2): 
    result = sonsLen(t2.n)
  else:
    result = lengthOrd(skipTypes(t, abstractVar-{tyTypeDesc}))

proc performProcvarCheck(c: PContext, n: PNode, s: PSym) =
  var smoduleId = getModule(s).id
  if sfProcVar notin s.flags and s.typ.callConv == ccDefault and
      smoduleId != c.module.id and smoduleId != c.friendModule.id: 
    LocalError(n.info, errXCannotBePassedToProcVar, s.name.s)

proc semProcvarCheck(c: PContext, n: PNode) =
  let n = n.skipConv
  if n.kind == nkSym and n.sym.kind in {skProc, skMethod, skIterator,
                                        skConverter}:
    performProcvarCheck(c, n, n.sym)

proc semProc(c: PContext, n: PNode): PNode

include semdestruct

proc semDestructorCheck(c: PContext, n: PNode, flags: TExprFlags) {.inline.} =
  if efAllowDestructor notin flags and n.kind in nkCallKinds+{nkObjConstr}:
    if instantiateDestructor(c, n.typ):
      LocalError(n.info, errGenerated,
        "usage of a type with a destructor in a non destructible context")
  # This still breaks too many things:
  when false:
    if efDetermineType notin flags and n.typ.kind == tyTypeDesc and 
        c.p.owner.kind notin {skTemplate, skMacro}:
      localError(n.info, errGenerated, "value expected, but got a type")

proc newDeref(n: PNode): PNode {.inline.} =  
  result = newNodeIT(nkHiddenDeref, n.info, n.typ.sons[0])
  addSon(result, n)

proc semExprBranch(c: PContext, n: PNode): PNode =
  result = semExpr(c, n)
  if result.typ != nil:
    # XXX tyGenericInst here?
    semProcvarCheck(c, result)
    if result.typ.kind == tyVar: result = newDeref(result)
    semDestructorCheck(c, result, {})

proc semExprBranchScope(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semExprBranch(c, n)
  closeScope(c)

const
  skipForDiscardable = {nkIfStmt, nkIfExpr, nkCaseStmt, nkOfBranch,
    nkElse, nkStmtListExpr, nkTryStmt, nkFinally, nkExceptBranch,
    nkElifBranch, nkElifExpr, nkElseExpr, nkBlockStmt, nkBlockExpr}

proc ImplicitlyDiscardable(n: PNode): bool =
  var n = n
  while n.kind in skipForDiscardable: n = n.lastSon
  result = isCallExpr(n) and n.sons[0].kind == nkSym and 
           sfDiscardable in n.sons[0].sym.flags

proc fixNilType(n: PNode) =
  if isAtom(n):
    if n.kind != nkNilLit and n.typ != nil:
      localError(n.info, errDiscardValue)
  elif n.kind in {nkStmtList, nkStmtListExpr}:
    n.kind = nkStmtList
    for it in n: fixNilType(it)
  n.typ = nil

proc discardCheck(c: PContext, result: PNode) =
  if result.typ != nil and result.typ.kind notin {tyStmt, tyEmpty}:
    if result.kind == nkNilLit:
      result.typ = nil
    elif ImplicitlyDiscardable(result):
      var n = result
      result.typ = nil
      while n.kind in skipForDiscardable:
        n = n.lastSon
        n.typ = nil
    elif c.InTypeClass > 0 and result.typ.kind == tyBool:
      let verdict = semConstExpr(c, result)
      if verdict.intVal == 0:
        localError(result.info, "type class predicate failed.")
    elif result.typ.kind != tyError and gCmd != cmdInteractive:
      if result.typ.kind == tyNil:
        fixNilType(result)
      else:
        var n = result
        while n.kind in skipForDiscardable: n = n.lastSon
        localError(n.info, errDiscardValue)

proc semIf(c: PContext, n: PNode): PNode = 
  result = n
  var typ = CommonTypeBegin
  var hasElse = false
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if it.len == 2:
      when newScopeForIf: openScope(c)
      it.sons[0] = forceBool(c, semExprWithType(c, it.sons[0]))
      when not newScopeForIf: openScope(c)
      it.sons[1] = semExprBranch(c, it.sons[1])
      typ = commonType(typ, it.sons[1].typ)
      closeScope(c)
    elif it.len == 1:
      hasElse = true
      it.sons[0] = semExprBranchScope(c, it.sons[0])
      typ = commonType(typ, it.sons[0].typ)
    else: illFormedAst(it)
  if isEmptyType(typ) or typ.kind == tyNil or not hasElse:
    for it in n: discardCheck(c, it.lastSon)
    result.kind = nkIfStmt
    # propagate any enforced VoidContext:
    if typ == EnforceVoidContext: result.typ = EnforceVoidContext
  else:
    for it in n:
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.kind = nkIfExpr
    result.typ = typ

proc semCase(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 2)
  openScope(c)
  n.sons[0] = semExprWithType(c, n.sons[0])
  var chckCovered = false
  var covered: biggestint = 0
  var typ = CommonTypeBegin
  var hasElse = false
  case skipTypes(n.sons[0].Typ, abstractVarRange-{tyTypeDesc}).Kind
  of tyInt..tyInt64, tyChar, tyEnum, tyUInt..tyUInt32:
    chckCovered = true
  of tyFloat..tyFloat128, tyString, tyError:
    nil
  else:
    LocalError(n.info, errSelectorMustBeOfCertainTypes)
    return
  for i in countup(1, sonsLen(n) - 1): 
    var x = n.sons[i]
    case x.kind
    of nkOfBranch: 
      checkMinSonsLen(x, 2)
      semCaseBranch(c, n, x, i, covered)
      var last = sonsLen(x)-1
      x.sons[last] = semExprBranchScope(c, x.sons[last])
      typ = commonType(typ, x.sons[last].typ)
    of nkElifBranch:
      chckCovered = false
      checkSonsLen(x, 2)
      when newScopeForIf: openScope(c)
      x.sons[0] = forceBool(c, semExprWithType(c, x.sons[0]))
      when not newScopeForIf: openScope(c)
      x.sons[1] = semExprBranch(c, x.sons[1])
      typ = commonType(typ, x.sons[1].typ)
      closeScope(c)
    of nkElse:
      chckCovered = false
      checkSonsLen(x, 1)
      x.sons[0] = semExprBranchScope(c, x.sons[0])
      typ = commonType(typ, x.sons[0].typ)
      hasElse = true
    else:
      illFormedAst(x)
  if chckCovered:
    if covered == toCover(n.sons[0].typ):
      hasElse = true
    else:
      localError(n.info, errNotAllCasesCovered)
  closeScope(c)
  if isEmptyType(typ) or typ.kind == tyNil or not hasElse:
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    # propagate any enforced VoidContext:
    if typ == EnforceVoidContext:
      result.typ = EnforceVoidContext
  else:
    for i in 1..n.len-1:
      var it = n.sons[i]
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.typ = typ

proc semTry(c: PContext, n: PNode): PNode =
  result = n
  inc c.p.inTryStmt
  checkMinSonsLen(n, 2)
  var typ = CommonTypeBegin
  n.sons[0] = semExprBranchScope(c, n.sons[0])
  typ = commonType(typ, n.sons[0].typ)
  var check = initIntSet()
  for i in countup(1, sonsLen(n) - 1): 
    var a = n.sons[i]
    checkMinSonsLen(a, 1)
    var length = sonsLen(a)
    if a.kind == nkExceptBranch:
      # XXX what does this do? so that ``except [a, b, c]`` is supported?
      if length == 2 and a.sons[0].kind == nkBracket:
        a.sons[0..0] = a.sons[0].sons
        length = a.sonsLen

      for j in countup(0, length-2):
        var typ = semTypeNode(c, a.sons[j], nil)
        if typ.kind == tyRef: typ = typ.sons[0]
        if typ.kind != tyObject:
          LocalError(a.sons[j].info, errExprCannotBeRaised)
        a.sons[j] = newNodeI(nkType, a.sons[j].info)
        a.sons[j].typ = typ
        if ContainsOrIncl(check, typ.id):
          localError(a.sons[j].info, errExceptionAlreadyHandled)
    elif a.kind != nkFinally: 
      illFormedAst(n)
    # last child of an nkExcept/nkFinally branch is a statement:
    a.sons[length-1] = semExprBranchScope(c, a.sons[length-1])
    typ = commonType(typ, a.sons[length-1].typ)
  dec c.p.inTryStmt
  if isEmptyType(typ) or typ.kind == tyNil:
    discardCheck(c, n.sons[0])
    for i in 1..n.len-1: discardCheck(c, n.sons[i].lastSon)
    if typ == EnforceVoidContext:
      result.typ = EnforceVoidContext
  else:
    n.sons[0] = fitNode(c, typ, n.sons[0])
    for i in 1..n.len-1:
      var it = n.sons[i]
      let j = it.len-1
      it.sons[j] = fitNode(c, typ, it.sons[j])
    result.typ = typ
  
proc fitRemoveHiddenConv(c: PContext, typ: Ptype, n: PNode): PNode = 
  result = fitNode(c, typ, n)
  if result.kind in {nkHiddenStdConv, nkHiddenSubConv}: 
    changeType(result.sons[1], typ, check=true)
    result = result.sons[1]
  elif not sameType(result.typ, typ):
    changeType(result, typ, check=false)

proc findShadowedVar(c: PContext, v: PSym): PSym =
  for scope in walkScopes(c.currentScope.parent):
    if scope == c.topLevelScope: break
    let shadowed = StrTableGet(scope.symbols, v.name)
    if shadowed != nil and shadowed.kind in skLocalVars:
      return shadowed

proc identWithin(n: PNode, s: PIdent): bool =
  for i in 0 .. n.safeLen-1:
    if identWithin(n.sons[i], s): return true
  result = n.kind == nkSym and n.sym.name.id == s.id

proc semIdentDef(c: PContext, n: PNode, kind: TSymKind): PSym =
  if isTopLevel(c): 
    result = semIdentWithPragma(c, kind, n, {sfExported})
    incl(result.flags, sfGlobal)
  else:
    result = semIdentWithPragma(c, kind, n, {})
  suggestSym(n, result)

proc checkNilable(v: PSym) =
  if sfGlobal in v.flags and {tfNotNil, tfNeedsInit} * v.typ.flags != {}:
    if v.ast.isNil:
      Message(v.info, warnProveInit, v.name.s)
    elif tfNotNil in v.typ.flags and tfNotNil notin v.ast.typ.flags:
      Message(v.info, warnProveInit, v.name.s)

proc semVarOrLet(c: PContext, n: PNode, symkind: TSymKind): PNode = 
  var b: PNode
  result = copyNode(n)
  for i in countup(0, sonsLen(n)-1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if a.kind notin {nkIdentDefs, nkVarTuple, nkConstDef}: IllFormedAst(a)
    checkMinSonsLen(a, 3)
    var length = sonsLen(a)
    var typ: PType
    if a.sons[length-2].kind != nkEmpty:
      typ = semTypeNode(c, a.sons[length-2], nil)
    else:
      typ = nil
    var def: PNode
    if a.sons[length-1].kind != nkEmpty:
      def = semExprWithType(c, a.sons[length-1], {efAllowDestructor})
      # BUGFIX: ``fitNode`` is needed here!
      # check type compability between def.typ and typ:
      if typ != nil: def = fitNode(c, typ, def)
      else: typ = skipIntLit(def.typ)
    else:
      def = ast.emptyNode
      if symkind == skLet: LocalError(a.info, errLetNeedsInit)
      
    # this can only happen for errornous var statements:
    if typ == nil: continue
    if not typeAllowed(typ, symkind): 
      LocalError(a.info, errXisNoType, typeToString(typ))
    var tup = skipTypes(typ, {tyGenericInst})
    if a.kind == nkVarTuple: 
      if tup.kind != tyTuple: 
        localError(a.info, errXExpected, "tuple")
      elif length-2 != sonsLen(tup): 
        localError(a.info, errWrongNumberOfVariables)
      else:
        b = newNodeI(nkVarTuple, a.info)
        newSons(b, length)
        b.sons[length-2] = a.sons[length-2] # keep type desc for doc generator
        b.sons[length-1] = def
        addSon(result, b)
    elif tup.kind == tyTuple and def.kind == nkPar and 
        a.kind == nkIdentDefs and a.len > 3:
      Message(a.info, warnEachIdentIsTuple)
    for j in countup(0, length-3):
      var v = semIdentDef(c, a.sons[j], symkind)
      if sfGenSym notin v.flags: addInterfaceDecl(c, v)
      when oKeepVariableNames:
        if c.InUnrolledContext > 0: v.flags.incl(sfShadowed)
        else:
          let shadowed = findShadowedVar(c, v)
          if shadowed != nil:
            shadowed.flags.incl(sfShadowed)
            # a shadowed variable is an error unless it appears on the right
            # side of the '=':
            if warnShadowIdent in gNotes and not identWithin(def, v.name):
              Message(a.info, warnShadowIdent, v.name.s)
      if a.kind != nkVarTuple:
        if def != nil and def.kind != nkEmpty:
          # this is needed for the evaluation pass and for the guard checking:
          v.ast = def
          if sfThread in v.flags: LocalError(def.info, errThreadvarCannotInit)
        v.typ = typ
        b = newNodeI(nkIdentDefs, a.info)
        if importantComments():
          # keep documentation information:
          b.comment = a.comment
        addSon(b, newSymNode(v))
        addSon(b, a.sons[length-2])      # keep type desc for doc generator
        addSon(b, copyTree(def))
        addSon(result, b)
      else:
        if def.kind == nkPar: v.ast = def[j]
        v.typ = tup.sons[j]
        b.sons[j] = newSymNode(v)
      checkNilable(v)
    
proc semConst(c: PContext, n: PNode): PNode = 
  result = copyNode(n)
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkConstDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    var v = semIdentDef(c, a.sons[0], skConst)
    var typ: PType = nil
    if a.sons[1].kind != nkEmpty: typ = semTypeNode(c, a.sons[1], nil)

    var def = semConstExpr(c, a.sons[2])
    if def == nil:
      LocalError(a.sons[2].info, errConstExprExpected)
      continue
    # check type compatibility between def.typ and typ:
    if typ != nil:
      def = fitRemoveHiddenConv(c, typ, def)
    else:
      typ = def.typ
    if typ == nil: continue
    if not typeAllowed(typ, skConst):
      LocalError(a.info, errXisNoType, typeToString(typ))
      continue
    v.typ = typ
    v.ast = def               # no need to copy
    if sfGenSym notin v.flags: addInterfaceDecl(c, v)
    var b = newNodeI(nkConstDef, a.info)
    if importantComments(): b.comment = a.comment
    addSon(b, newSymNode(v))
    addSon(b, a.sons[1])
    addSon(b, copyTree(def))
    addSon(result, b)

type
  TFieldInstCtx = object  # either 'tup[i]' or 'field' is valid
    tupleType: PType      # if != nil we're traversing a tuple
    tupleIndex: int
    field: PSym
    replaceByFieldName: bool

proc instFieldLoopBody(c: TFieldInstCtx, n: PNode, forLoop: PNode): PNode =
  case n.kind
  of nkEmpty..pred(nkIdent), succ(nkIdent)..nkNilLit: result = n
  of nkIdent:
    result = n
    var L = sonsLen(forLoop)
    if c.replaceByFieldName:
      if n.ident.id == forLoop[0].ident.id:
        let fieldName = if c.tupleType.isNil: c.field.name.s
                        elif c.tupleType.n.isNil: "Field" & $c.tupleIndex
                        else: c.tupleType.n.sons[c.tupleIndex].sym.name.s
        result = newStrNode(nkStrLit, fieldName)
        return
    # other fields:
    for i in ord(c.replaceByFieldName)..L-3:
      if n.ident.id == forLoop[i].ident.id:
        var call = forLoop.sons[L-2]
        var tupl = call.sons[i+1-ord(c.replaceByFieldName)]
        if c.field.isNil:
          result = newNodeI(nkBracketExpr, n.info)
          result.add(tupl)
          result.add(newIntNode(nkIntLit, c.tupleIndex))
        else:
          result = newNodeI(nkDotExpr, n.info)
          result.add(tupl)
          result.add(newSymNode(c.field, n.info))
        break
  else:
    if n.kind == nkContinueStmt:
      localError(n.info, errGenerated,
                 "'continue' not supported in a 'fields' loop")
    result = copyNode(n)
    newSons(result, sonsLen(n))
    for i in countup(0, sonsLen(n)-1):
      result.sons[i] = instFieldLoopBody(c, n.sons[i], forLoop)

type
  TFieldsCtx = object
    c: PContext
    m: TMagic

proc semForObjectFields(c: TFieldsCtx, typ, forLoop, father: PNode) =
  case typ.kind
  of nkSym:
    var fc: TFieldInstCtx  # either 'tup[i]' or 'field' is valid
    fc.field = typ.sym
    fc.replaceByFieldName = c.m == mFieldPairs
    openScope(c.c)
    inc c.c.InUnrolledContext
    let body = instFieldLoopBody(fc, lastSon(forLoop), forLoop)
    father.add(SemStmt(c.c, body))
    dec c.c.InUnrolledContext
    closeScope(c.c)
  of nkNilLit: nil
  of nkRecCase:
    let L = forLoop.len
    let call = forLoop.sons[L-2]
    if call.len > 2:
      LocalError(forLoop.info, errGenerated, 
                 "parallel 'fields' iterator does not work for 'case' objects")
      return
    # iterate over the selector:
    semForObjectFields(c, typ[0], forLoop, father)
    # we need to generate a case statement:
    var caseStmt = newNodeI(nkCaseStmt, forLoop.info)
    # generate selector:
    var access = newNodeI(nkDotExpr, forLoop.info, 2)
    access.sons[0] = call.sons[1]
    access.sons[1] = newSymNode(typ.sons[0].sym, forLoop.info)
    caseStmt.add(semExprWithType(c.c, access))
    # copy the branches over, but replace the fields with the for loop body:
    for i in 1 .. <typ.len:
      var branch = copyTree(typ[i])
      let L = branch.len
      branch.sons[L-1] = newNodeI(nkStmtList, forLoop.info)
      semForObjectFields(c, typ[i].lastSon, forLoop, branch[L-1])
      caseStmt.add(branch)
    father.add(caseStmt)
  of nkRecList:
    for t in items(typ): semForObjectFields(c, t, forLoop, father)
  else:
    illFormedAst(typ)

proc semForFields(c: PContext, n: PNode, m: TMagic): PNode =
  # so that 'break' etc. work as expected, we produce
  # a 'while true: stmt; break' loop ...
  result = newNodeI(nkWhileStmt, n.info, 2)
  var trueSymbol = StrTableGet(magicsys.systemModule.Tab, getIdent"true")
  if trueSymbol == nil: 
    LocalError(n.info, errSystemNeeds, "true")
    trueSymbol = newSym(skUnknown, getIdent"true", getCurrOwner(), n.info)
    trueSymbol.typ = getSysType(tyBool)

  result.sons[0] = newSymNode(trueSymbol, n.info)
  var stmts = newNodeI(nkStmtList, n.info)
  result.sons[1] = stmts
  
  var length = sonsLen(n)
  var call = n.sons[length-2]
  if length-2 != sonsLen(call)-1 + ord(m==mFieldPairs):
    LocalError(n.info, errWrongNumberOfVariables)
    return result
  
  var tupleTypeA = skipTypes(call.sons[1].typ, abstractVar-{tyTypeDesc})
  if tupleTypeA.kind notin {tyTuple, tyObject}:
    localError(n.info, errGenerated, "no object or tuple type")
    return result
  for i in 1..call.len-1:
    var tupleTypeB = skipTypes(call.sons[i].typ, abstractVar-{tyTypeDesc})
    if not SameType(tupleTypeA, tupleTypeB):
      typeMismatch(call.sons[i], tupleTypeA, tupleTypeB)
  
  Inc(c.p.nestedLoopCounter)
  if tupleTypeA.kind == tyTuple:
    var loopBody = n.sons[length-1]
    for i in 0..sonsLen(tupleTypeA)-1:
      openScope(c)
      var fc: TFieldInstCtx
      fc.tupleType = tupleTypeA
      fc.tupleIndex = i
      fc.replaceByFieldName = m == mFieldPairs
      var body = instFieldLoopBody(fc, loopBody, n)
      inc c.InUnrolledContext
      stmts.add(SemStmt(c, body))
      dec c.InUnrolledContext
      closeScope(c)
  else:
    var fc: TFieldsCtx
    fc.m = m
    fc.c = c
    semForObjectFields(fc, tupleTypeA.n, n, stmts)
  Dec(c.p.nestedLoopCounter)
  # for TR macros this 'while true: ...; break' loop is pretty bad, so
  # we avoid it now if we can:
  if hasSonWith(stmts, nkBreakStmt):
    var b = newNodeI(nkBreakStmt, n.info)
    b.add(ast.emptyNode)
    stmts.add(b)
  else:
    result = stmts

proc addForVarDecl(c: PContext, v: PSym) =
  if warnShadowIdent in gNotes:
    let shadowed = findShadowedVar(c, v)
    if shadowed != nil:
      # XXX should we do this here?
      #shadowed.flags.incl(sfShadowed)
      Message(v.info, warnShadowIdent, v.name.s)
  addDecl(c, v)

proc symForVar(c: PContext, n: PNode): PSym =
  let m = if n.kind == nkPragmaExpr: n.sons[0] else: n
  result = newSymG(skForVar, m, c)

proc semForVars(c: PContext, n: PNode): PNode =
  result = n
  var length = sonsLen(n)
  var iter = skipTypes(n.sons[length-2].typ, {tyGenericInst})
  # length == 3 means that there is one for loop variable
  # and thus no tuple unpacking:
  if iter.kind != tyTuple or length == 3: 
    if length == 3:
      var v = symForVar(c, n.sons[0])
      if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
      # BUGFIX: don't use `iter` here as that would strip away
      # the ``tyGenericInst``! See ``tests/compile/tgeneric.nim``
      # for an example:
      v.typ = n.sons[length-2].typ
      n.sons[0] = newSymNode(v)
      if sfGenSym notin v.flags: addForVarDecl(c, v)
    else:
      LocalError(n.info, errWrongNumberOfVariables)
  elif length-2 != sonsLen(iter):
    LocalError(n.info, errWrongNumberOfVariables)
  else:
    for i in countup(0, length - 3):
      var v = symForVar(c, n.sons[i])
      if getCurrOwner().kind == skModule: incl(v.flags, sfGlobal)
      v.typ = iter.sons[i]
      n.sons[i] = newSymNode(v)
      if sfGenSym notin v.flags: addForVarDecl(c, v)
  Inc(c.p.nestedLoopCounter)
  n.sons[length-1] = SemStmt(c, n.sons[length-1])
  Dec(c.p.nestedLoopCounter)

proc implicitIterator(c: PContext, it: string, arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info)
  result.add(newIdentNode(it.getIdent, arg.info))
  if arg.typ != nil and arg.typ.kind == tyVar: 
    result.add newDeref(arg)
  else:
    result.add arg
  result = semExprNoDeref(c, result, {efWantIterator})

proc semFor(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 3)
  var length = sonsLen(n)
  openScope(c)
  n.sons[length-2] = semExprNoDeref(c, n.sons[length-2], {efWantIterator})
  var call = n.sons[length-2]
  if call.kind in nkCallKinds and call.sons[0].typ.callConv == ccClosure:
    # first class iterator:
    result = semForVars(c, n)
  elif call.kind notin nkCallKinds or call.sons[0].kind != nkSym or
      call.sons[0].sym.kind != skIterator: 
    if length == 3:
      n.sons[length-2] = implicitIterator(c, "items", n.sons[length-2])
    elif length == 4:
      n.sons[length-2] = implicitIterator(c, "pairs", n.sons[length-2])
    else:
      LocalError(n.sons[length-2].info, errIteratorExpected)
    result = semForVars(c, n)
  elif call.sons[0].sym.magic != mNone:
    if call.sons[0].sym.magic == mOmpParFor:
      result = semForVars(c, n)
      result.kind = nkParForStmt
    else:
      result = semForFields(c, n, call.sons[0].sym.magic)
  else:
    result = semForVars(c, n)
  # propagate any enforced VoidContext:
  if n.sons[length-1].typ == EnforceVoidContext:
    result.typ = EnforceVoidContext
  closeScope(c)

proc semRaise(c: PContext, n: PNode): PNode = 
  result = n
  checkSonsLen(n, 1)
  if n.sons[0].kind != nkEmpty: 
    n.sons[0] = semExprWithType(c, n.sons[0])
    var typ = n.sons[0].typ
    if typ.kind != tyRef or typ.sons[0].kind != tyObject: 
      localError(n.info, errExprCannotBeRaised)

proc addGenericParamListToScope(c: PContext, n: PNode) =
  if n.kind != nkGenericParams: illFormedAst(n)
  for i in countup(0, sonsLen(n)-1):
    var a = n.sons[i]
    if a.kind == nkSym: addDecl(c, a.sym)
    else: illFormedAst(a)

proc typeSectionLeftSidePass(c: PContext, n: PNode) = 
  # process the symbols on the left side for the whole type section, before
  # we even look at the type definitions on the right
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if gCmd == cmdIdeTools: suggestStmt(c, a)
    if a.kind == nkCommentStmt: continue 
    if a.kind != nkTypeDef: IllFormedAst(a)
    checkSonsLen(a, 3)
    var s = semIdentDef(c, a.sons[0], skType)
    s.typ = newTypeS(tyForward, c)
    s.typ.sym = s             # process pragmas:
    if a.sons[0].kind == nkPragmaExpr:
      pragma(c, s, a.sons[0].sons[1], typePragmas)
    # add it here, so that recursive types are possible:
    if sfGenSym notin s.flags: addInterfaceDecl(c, s)
    a.sons[0] = newSymNode(s)

proc typeSectionRightSidePass(c: PContext, n: PNode) =
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if (a.kind != nkTypeDef): IllFormedAst(a)
    checkSonsLen(a, 3)
    if (a.sons[0].kind != nkSym): IllFormedAst(a)
    var s = a.sons[0].sym
    if s.magic == mNone and a.sons[2].kind == nkEmpty: 
      LocalError(a.info, errImplOfXexpected, s.name.s)
    if s.magic != mNone: processMagicType(c, s)
    if a.sons[1].kind != nkEmpty: 
      # We have a generic type declaration here. In generic types,
      # symbol lookup needs to be done here.
      openScope(c)
      pushOwner(s)
      if s.magic == mNone: s.typ.kind = tyGenericBody
      # XXX for generic type aliases this is not correct! We need the
      # underlying Id really: 
      #
      # type
      #   TGObj[T] = object
      #   TAlias[T] = TGObj[T]
      # 
      s.typ.n = semGenericParamList(c, a.sons[1], s.typ)
      a.sons[1] = s.typ.n
      s.typ.size = -1 # could not be computed properly
      # we fill it out later. For magic generics like 'seq', it won't be filled
      # so we use tyEmpty instead of nil to not crash for strange conversions
      # like: mydata.seq
      rawAddSon(s.typ, newTypeS(tyEmpty, c))
      s.ast = a
      when oUseLateInstantiation:
        var body: PType = nil
        s.typScope = c.currentScope.parent
      else:
        inc c.InGenericContext
        var body = semTypeNode(c, a.sons[2], nil)
        dec c.InGenericContext
        if body != nil:
          body.sym = s
          body.size = -1 # could not be computed properly
      s.typ.sons[sonsLen(s.typ) - 1] = body
      popOwner()
      closeScope(c)
    elif a.sons[2].kind != nkEmpty: 
      # process the type's body:
      pushOwner(s)
      var t = semTypeNode(c, a.sons[2], s.typ)
      if s.typ == nil: 
        s.typ = t
      elif t != s.typ: 
        # this can happen for e.g. tcan_alias_specialised_generic:
        assignType(s.typ, t)
        #debug s.typ
      s.ast = a
      popOwner()

proc typeSectionFinalPass(c: PContext, n: PNode) = 
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if a.sons[0].kind != nkSym: IllFormedAst(a)
    var s = a.sons[0].sym
    # compute the type's size and check for illegal recursions:
    if a.sons[1].kind == nkEmpty: 
      if a.sons[2].kind in {nkSym, nkIdent, nkAccQuoted}:
        # type aliases are hard:
        #MessageOut('for type ' + typeToString(s.typ));
        var t = semTypeNode(c, a.sons[2], nil)
        if t.kind in {tyObject, tyEnum}: 
          assignType(s.typ, t)
          s.typ.id = t.id     # same id
      checkConstructedType(s.info, s.typ)
    let aa = a.sons[2]
    if aa.kind in {nkRefTy, nkPtrTy} and aa.len == 1 and
       aa.sons[0].kind == nkObjectTy:
      # give anonymous object a dummy symbol:
      var st = s.typ
      if st.kind == tyGenericBody: st = st.lastSon
      InternalAssert st.kind in {tyPtr, tyRef}
      InternalAssert st.sons[0].sym == nil
      st.sons[0].sym = newSym(skType, getIdent(s.name.s & ":ObjectType"),
                              getCurrOwner(), s.info)

proc SemTypeSection(c: PContext, n: PNode): PNode =
  typeSectionLeftSidePass(c, n)
  typeSectionRightSidePass(c, n)
  typeSectionFinalPass(c, n)
  result = n

proc semParamList(c: PContext, n, genericParams: PNode, s: PSym) =
  s.typ = semProcTypeNode(c, n, genericParams, nil, s.kind)
  if s.kind notin {skMacro, skTemplate}:
    if s.typ.sons[0] != nil and s.typ.sons[0].kind == tyStmt:
      localError(n.info, errGenerated, "invalid return type: 'stmt'")

proc addParams(c: PContext, n: PNode, kind: TSymKind) = 
  for i in countup(1, sonsLen(n)-1): 
    if n.sons[i].kind == nkSym: addParamOrResult(c, n.sons[i].sym, kind)
    else: illFormedAst(n)

proc semBorrow(c: PContext, n: PNode, s: PSym) = 
  # search for the correct alias:
  var b = SearchForBorrowProc(c, c.currentScope.parent, s)
  if b != nil: 
    # store the alias:
    n.sons[bodyPos] = newSymNode(b)
  else:
    LocalError(n.info, errNoSymbolToBorrowFromFound) 
  
proc addResult(c: PContext, t: PType, info: TLineInfo, owner: TSymKind) = 
  if t != nil: 
    var s = newSym(skResult, getIdent"result", getCurrOwner(), info)
    s.typ = t
    incl(s.flags, sfUsed)
    addParamOrResult(c, s, owner)
    c.p.resultSym = s

proc addResultNode(c: PContext, n: PNode) = 
  if c.p.resultSym != nil: addSon(n, newSymNode(c.p.resultSym))

proc copyExcept(n: PNode, i: int): PNode =
  result = copyNode(n)
  for j in 0.. <n.len:
    if j != i: result.add(n.sons[j])

proc lookupMacro(c: PContext, n: PNode): PSym =
  if n.kind == nkSym:
    result = n.sym
    if result.kind notin {skMacro, skTemplate}: result = nil
  else:
    result = searchInScopes(c, considerAcc(n), {skMacro, skTemplate})

proc semProcAnnotation(c: PContext, prc: PNode): PNode =
  var n = prc.sons[pragmasPos]
  if n == nil or n.kind == nkEmpty: return
  for i in countup(0, <n.len):
    var it = n.sons[i]
    var key = if it.kind == nkExprColonExpr: it.sons[0] else: it
    let m = lookupMacro(c, key)
    if m == nil:
      if key.kind == nkIdent and key.ident.id == ord(wDelegator):
        if considerAcc(prc.sons[namePos]).s == "()":
          prc.sons[namePos] = newIdentNode(idDelegator, prc.info)
          prc.sons[pragmasPos] = copyExcept(n, i)
        else:
          LocalError(prc.info, errOnlyACallOpCanBeDelegator)
      continue
    # we transform ``proc p {.m, rest.}`` into ``m(do: proc p {.rest.})`` and
    # let the semantic checker deal with it:
    var x = newNodeI(nkCall, n.info)
    x.add(newSymNode(m))
    prc.sons[pragmasPos] = copyExcept(n, i)
    if it.kind == nkExprColonExpr:
      # pass pragma argument to the macro too:
      x.add(it.sons[1])
    x.add(newProcNode(nkDo, prc.info, prc))
    # recursion assures that this works for multiple macro annotations too:
    return semStmt(c, x)

proc semLambda(c: PContext, n: PNode, flags: TExprFlags): PNode =
  result = semProcAnnotation(c, n)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s: PSym
  if n[namePos].kind != nkSym:
    s = newSym(skProc, idAnon, getCurrOwner(), n.info)
    s.ast = n
    n.sons[namePos] = newSymNode(s)
  else:
    s = n[namePos].sym
  pushOwner(s)
  openScope(c)
  if n.sons[genericParamsPos].kind != nkEmpty:
    illFormedAst(n)           # process parameters:
  if n.sons[paramsPos].kind != nkEmpty:
    var gp = newNodeI(nkGenericParams, n.info)
    semParamList(c, n.sons[ParamsPos], gp, s)
    ParamsTypeCheck(c, s.typ)
  else:
    s.typ = newTypeS(tyProc, c)
    rawAddSon(s.typ, nil)
  if n.sons[pragmasPos].kind != nkEmpty:
    pragma(c, s, n.sons[pragmasPos], lambdaPragmas)
  s.options = gOptions
  if n.sons[bodyPos].kind != nkEmpty:
    if sfImportc in s.flags:
      LocalError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    #if efDetermineType notin flags:
    # XXX not good enough; see tnamedparamanonproc.nim
    pushProcCon(c, s)
    addResult(c, s.typ.sons[0], n.info, skProc)
    let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
    n.sons[bodyPos] = transformBody(c.module, semBody, s)
    addResultNode(c, n)
    popProcCon(c)
    sideEffectsCheck(c, s)
  else:
    LocalError(n.info, errImplOfXexpected, s.name.s)
  closeScope(c)           # close scope for parameters
  popOwner()
  result.typ = s.typ

proc activate(c: PContext, n: PNode) =
  # XXX: This proc is part of my plan for getting rid of
  # forward declarations. stay tuned.
  when false:
    # well for now it breaks code ...
    case n.kind
    of nkLambdaKinds:
      discard semLambda(c, n, {})
    of nkCallKinds:
      for i in 1 .. <n.len: activate(c, n[i])
    else:
      nil

proc maybeAddResult(c: PContext, s: PSym, n: PNode) =
  if s.typ.sons[0] != nil and
      (s.kind != skIterator or s.typ.callConv == ccClosure):
    addResult(c, s.typ.sons[0], n.info, s.kind)
    addResultNode(c, n)

type
  TProcCompilationSteps = enum
    stepRegisterSymbol,
    stepDetermineType,
    stepCompileBody

proc isForwardDecl(s: PSym): bool =
  InternalAssert s.kind == skProc
  result = s.ast[bodyPos].kind != nkEmpty

proc semProcAux(c: PContext, n: PNode, kind: TSymKind,
                validPragmas: TSpecialWords,
                phase = stepRegisterSymbol): PNode =
  result = semProcAnnotation(c, n)
  if result != nil: return result
  result = n
  checkSonsLen(n, bodyPos + 1)
  var s: PSym
  var typeIsDetermined = false
  if n[namePos].kind != nkSym:
    assert phase == stepRegisterSymbol
    s = semIdentDef(c, n.sons[0], kind)
    n.sons[namePos] = newSymNode(s)
    s.ast = n
    s.scope = c.currentScope

    if sfNoForward in c.module.flags and
       sfSystemModule notin c.module.flags:
      addInterfaceOverloadableSymAt(c, c.currentScope, s)
      s.flags.incl sfForward
      return
  else:
    s = n[namePos].sym
    typeIsDetermined = s.typ == nil
    # if typeIsDetermined: assert phase == stepCompileBody
    # else: assert phase == stepDetermineType
  # before compiling the proc body, set as current the scope
  # where the proc was declared
  let oldScope = c.currentScope
  c.currentScope = s.scope
  pushOwner(s)
  openScope(c)
  var gp: PNode
  if n.sons[genericParamsPos].kind != nkEmpty: 
    n.sons[genericParamsPos] = semGenericParamList(c, n.sons[genericParamsPos])
    gp = n.sons[genericParamsPos]
  else: 
    gp = newNodeI(nkGenericParams, n.info)
  # process parameters:
  if n.sons[paramsPos].kind != nkEmpty:
    semParamList(c, n.sons[ParamsPos], gp, s)
    if sonsLen(gp) > 0: 
      if n.sons[genericParamsPos].kind == nkEmpty:
        # we have a list of implicit type parameters:
        n.sons[genericParamsPos] = gp
        # check for semantics again:
        # semParamList(c, n.sons[ParamsPos], nil, s)
  else:
    s.typ = newTypeS(tyProc, c)
    rawAddSon(s.typ, nil)
  if n.sons[patternPos].kind != nkEmpty:
    n.sons[patternPos] = semPattern(c, n.sons[patternPos])
  if s.kind == skIterator: s.typ.flags.incl(tfIterator)
  
  var proto = SearchForProc(c, s.scope, s)
  if proto == nil: 
    s.typ.callConv = lastOptionEntry(c).defaultCC
    # add it here, so that recursive procs are possible:
    if sfGenSym in s.flags: nil
    elif kind in OverloadableSyms:
      if not typeIsDetermined:
        addInterfaceOverloadableSymAt(c, s.scope, s)
    else:
      if not typeIsDetermined:
        addInterfaceDeclAt(c, s.scope, s)
    if n.sons[pragmasPos].kind != nkEmpty:
      pragma(c, s, n.sons[pragmasPos], validPragmas)
    else:
      implictPragmas(c, s, n, validPragmas)
  else: 
    if n.sons[pragmasPos].kind != nkEmpty: 
      LocalError(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc)
    if sfForward notin proto.flags: 
      WrongRedefinition(n.info, proto.name.s)
    excl(proto.flags, sfForward)
    closeScope(c)         # close scope with wrong parameter symbols
    openScope(c)          # open scope for old (correct) parameter symbols
    if proto.ast.sons[genericParamsPos].kind != nkEmpty: 
      addGenericParamListToScope(c, proto.ast.sons[genericParamsPos])
    addParams(c, proto.typ.n, proto.kind)
    proto.info = s.info       # more accurate line information
    s.typ = proto.typ
    s = proto
    n.sons[genericParamsPos] = proto.ast.sons[genericParamsPos]
    n.sons[paramsPos] = proto.ast.sons[paramsPos]
    n.sons[pragmasPos] = proto.ast.sons[pragmasPos]
    if n.sons[namePos].kind != nkSym: InternalError(n.info, "semProcAux")
    n.sons[namePos].sym = proto
    if importantComments() and not isNil(proto.ast.comment):
      n.comment = proto.ast.comment
    proto.ast = n             # needed for code generation
    popOwner()
    pushOwner(s)
  s.options = gOptions
  if sfDestructor in s.flags: doDestructorStuff(c, s, n)
  if n.sons[bodyPos].kind != nkEmpty: 
    # for DLL generation it is annoying to check for sfImportc!
    if sfBorrow in s.flags: 
      LocalError(n.sons[bodyPos].info, errImplOfXNotAllowed, s.name.s)
    if n.sons[genericParamsPos].kind == nkEmpty: 
      ParamsTypeCheck(c, s.typ)
      pushProcCon(c, s)
      maybeAddResult(c, s, n)
      if sfImportc notin s.flags:
        # no semantic checking for importc:
        let semBody = hloBody(c, semProcBody(c, n.sons[bodyPos]))
        # unfortunately we cannot skip this step when in 'system.compiles'
        # context as it may even be evaluated in 'system.compiles':
        n.sons[bodyPos] = transformBody(c.module, semBody, s)
      popProcCon(c)
    else: 
      if s.typ.sons[0] != nil and kind != skIterator:
        addDecl(c, newSym(skUnknown, getIdent"result", nil, n.info))
      var toBind = initIntSet()
      n.sons[bodyPos] = semGenericStmtScope(c, n.sons[bodyPos], {}, toBind)
      fixupInstantiatedSymbols(c, s)
    if sfImportc in s.flags: 
      # so we just ignore the body after semantic checking for importc:
      n.sons[bodyPos] = ast.emptyNode
  else:
    if proto != nil: LocalError(n.info, errImplOfXexpected, proto.name.s)
    if {sfImportc, sfBorrow} * s.flags == {} and s.magic == mNone: 
      incl(s.flags, sfForward)
    elif sfBorrow in s.flags: semBorrow(c, n, s)
  sideEffectsCheck(c, s)
  closeScope(c)           # close scope for parameters
  c.currentScope = oldScope
  popOwner()
  if n.sons[patternPos].kind != nkEmpty:
    c.patterns.add(s)

proc determineType(c: PContext, s: PSym) =
  if s.typ != nil: return
  #if s.magic != mNone: return
  discard semProcAux(c, s.ast, s.kind, {}, stepDetermineType)

proc semIterator(c: PContext, n: PNode): PNode =
  result = semProcAux(c, n, skIterator, iteratorPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil and s.typ.callConv != ccClosure:
    LocalError(n.info, errXNeedsReturnType, "iterator")
  # iterators are either 'inline' or 'closure'; for backwards compatibility,
  # we require first class iterators to be marked with 'closure' explicitly
  # -- at least for 0.9.2.
  if s.typ.callConv == ccClosure:
    incl(s.typ.flags, tfCapturesEnv)
  else:
    s.typ.callConv = ccInline
  when false:
    if s.typ.callConv != ccInline: 
      s.typ.callConv = ccClosure
      # and they always at least use the 'env' for the state field:
      incl(s.typ.flags, tfCapturesEnv)
  if n.sons[bodyPos].kind == nkEmpty and s.magic == mNone:
    LocalError(n.info, errImplOfXexpected, s.name.s)
  
proc semProc(c: PContext, n: PNode): PNode = 
  result = semProcAux(c, n, skProc, procPragmas)

proc hasObjParam(s: PSym): bool =
  var t = s.typ
  for col in countup(1, sonsLen(t)-1):
    if skipTypes(t.sons[col], skipPtrs).kind == tyObject:
      return true

proc finishMethod(c: PContext, s: PSym) =
  if hasObjParam(s):
    methodDef(s, false)

proc semMethod(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "method")
  result = semProcAux(c, n, skMethod, methodPragmas)
  
  var s = result.sons[namePos].sym
  if not isGenericRoutine(s) and result.sons[bodyPos].kind != nkEmpty:
    if hasObjParam(s):
      methodDef(s, fromCache=false)
    else:
      localError(n.info, errXNeedsParamObjectType, "method")

proc semConverterDef(c: PContext, n: PNode): PNode = 
  if not isTopLevel(c): localError(n.info, errXOnlyAtModuleScope, "converter")
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skConverter, converterPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: localError(n.info, errXNeedsReturnType, "converter")
  if sonsLen(t) != 2: localError(n.info, errXRequiresOneArgument, "converter")
  addConverter(c, s)

proc semMacroDef(c: PContext, n: PNode): PNode = 
  checkSonsLen(n, bodyPos + 1)
  result = semProcAux(c, n, skMacro, macroPragmas)
  var s = result.sons[namePos].sym
  var t = s.typ
  if t.sons[0] == nil: localError(n.info, errXNeedsReturnType, "macro")
  if n.sons[bodyPos].kind == nkEmpty:
    localError(n.info, errImplOfXexpected, s.name.s)
  
proc evalInclude(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStmtList, n.info)
  addSon(result, n)
  for i in countup(0, sonsLen(n) - 1): 
    var f = checkModuleName(n.sons[i])
    if f != InvalidFileIDX:
      if ContainsOrIncl(c.includedFiles, f): 
        LocalError(n.info, errRecursiveDependencyX, f.toFilename)
      else:
        addSon(result, semStmt(c, gIncludeFile(c.module, f)))
        Excl(c.includedFiles, f)
  
proc setLine(n: PNode, info: TLineInfo) =
  for i in 0 .. <safeLen(n): setLine(n.sons[i], info)
  n.info = info
  
proc semPragmaBlock(c: PContext, n: PNode): PNode =
  let pragmaList = n.sons[0]
  pragma(c, nil, pragmaList, exprPragmas)
  result = semStmt(c, n.sons[1])
  for i in 0 .. <pragmaList.len:
    if whichPragma(pragmaList.sons[i]) == wLine:
      setLine(result, pragmaList.sons[i].info)

proc semStaticStmt(c: PContext, n: PNode): PNode =
  let a = semStmt(c, n.sons[0])
  result = evalStaticExpr(c, c.module, a, c.p.owner)
  if result.isNil:
    LocalError(n.info, errCannotInterpretNodeX, renderTree(n))
    result = emptyNode
  elif result.kind == nkEmpty:
    result = newNodeI(nkDiscardStmt, n.info, 1)
    result.sons[0] = emptyNode

proc usesResult(n: PNode): bool =
  # nkStmtList(expr) properly propagates the void context,
  # so we don't need to process that all over again:
  if n.kind notin {nkStmtList, nkStmtListExpr} + procDefs:
    if isAtom(n):
      result = n.kind == nkSym and n.sym.kind == skResult
    elif n.kind == nkReturnStmt:
      result = true
    else:
      for c in n:
        if usesResult(c): return true

proc semStmtList(c: PContext, n: PNode): PNode =
  # these must be last statements in a block:
  const
    LastBlockStmts = {nkRaiseStmt, nkReturnStmt, nkBreakStmt, nkContinueStmt}
  result = n
  result.kind = nkStmtList
  var length = sonsLen(n)
  var voidContext = false
  var last = length-1
  # by not allowing for nkCommentStmt etc. we ensure nkStmtListExpr actually
  # really *ends* in the expression that produces the type: The compiler now
  # relies on this fact and it's too much effort to change that. And arguably
  #  'R(); #comment' shouldn't produce R's type anyway.
  #while last > 0 and n.sons[last].kind in {nkPragma, nkCommentStmt,
  #                                         nkNilLit, nkEmpty}:
  #  dec last
  for i in countup(0, length - 1):
    case n.sons[i].kind
    of nkFinally, nkExceptBranch:
      # stand-alone finally and except blocks are
      # transformed into regular try blocks:
      #
      # var f = fopen("somefile") | var f = fopen("somefile")
      # finally: fclose(f)        | try:
      # ...                       |   ...
      #                           | finally:
      #                           |   fclose(f)
      var tryStmt = newNodeI(nkTryStmt, n.sons[i].info)
      var body = newNodeI(nkStmtList, n.sons[i].info)
      if i < n.sonsLen - 1:
        body.sons = n.sons[(i+1)..(-1)]
      tryStmt.addSon(body)
      tryStmt.addSon(n.sons[i])
      n.sons[i] = semTry(c, tryStmt)
      n.sons.setLen(i+1)
      return
    else:
      n.sons[i] = semExpr(c, n.sons[i])
      if n.sons[i].typ == EnforceVoidContext or usesResult(n.sons[i]):
        voidContext = true
        n.typ = EnforceVoidContext
      if i != last or voidContext:
        discardCheck(c, n.sons[i])
      else:
        n.typ = n.sons[i].typ
        if not isEmptyType(n.typ):
          n.kind = nkStmtListExpr
      case n.sons[i].kind
      of nkVarSection, nkLetSection:
        let (outer, inner) = insertDestructors(c, n.sons[i])
        if outer != nil:
          n.sons[i] = outer
          for j in countup(i+1, length-1):
            inner.addSon(SemStmt(c, n.sons[j]))
          n.sons.setLen(i+1)
          return
      of LastBlockStmts: 
        for j in countup(i + 1, length - 1): 
          case n.sons[j].kind
          of nkPragma, nkCommentStmt, nkNilLit, nkEmpty: nil
          else: localError(n.sons[j].info, errStmtInvalidAfterReturn)
      else: nil
  if result.len == 1:
    result = result.sons[0]
  when false:
    # a statement list (s; e) has the type 'e':
    if result.kind == nkStmtList and result.len > 0:
      var lastStmt = lastSon(result)
      if lastStmt.kind != nkNilLit and not ImplicitlyDiscardable(lastStmt):
        result.typ = lastStmt.typ
        #localError(lastStmt.info, errGenerated,
        #  "Last expression must be explicitly returned if it " &
        #  "is discardable or discarded")

proc SemStmt(c: PContext, n: PNode): PNode = 
  # now: simply an alias:
  result = semExprNoType(c, n)

proc semStmtScope(c: PContext, n: PNode): PNode =
  openScope(c)
  result = semStmt(c, n)
  closeScope(c)
