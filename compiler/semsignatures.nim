#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module does the semantic checking for proc signatures
# included from sem.nim

from reorder import accQuoted, includeModule

proc patchNode(c: PContext; n: PNode; name: PIdent; kind: TSymKind) =
  var s = newSym(kind, n.ident, nextSymId(c.idgen), c.module, n.info)
  s.flags.incl sfForward
  let obj = n[]
  n[] = TNode(kind: nkSym, typ: nil, info: obj.info, flags: obj.flags, sym: s)

  if kind in OverloadableSyms:
    addInterfaceOverloadableSymAt(c, c.currentScope, s)
  else:
    addInterfaceDeclAt(c, c.currentScope, s)


proc decl(c: PContext; n: PNode; kind: TSymKind) =
  # mutates n directly.
  case n.kind
  of nkPostfix: decl(c, n[1], kind)
  of nkPragmaExpr: decl(c, n[0], kind)
  of nkIdent:
    patchNode(c, n, n.ident, kind)
  of nkAccQuoted:
    let a = accQuoted(c.graph.cache, n)
    patchNode(c, n, a, kind)
  of nkEnumFieldDef:
    decl(c, n[0], kind)
  else: discard

proc declLoop(c: PContext; n: PNode; kind: TSymKind) =
  for a in n:
    if a.kind in {nkIdentDefs, nkVarTuple}:
      for j in 0..<a.len-2: decl(c, a[j], kind)

proc topLevelDecl(c: PContext; n: PNode): PNode =
  result = n
  case n.kind
  of nkStmtList, nkStmtListExpr:
    result = newNodeI(n.kind, n.info, n.len)
    for i in 0..<n.len:
      result[i] = topLevelDecl(c, n[i])
  of nkIncludeStmt:
    for i in 0..<n.len:
      var f = checkModuleName(c.config, n[i])
      if f != InvalidFileIdx:
        if containsOrIncl(c.includedFiles, f.int):
          localError(c.config, n[i].info, "recursive dependency: '$1'" %
            toMsgFilename(c.config, f))
        else:
          let nn = includeModule(c.graph, c.module, f)
          result = topLevelDecl(c, nn)
          excl(c.includedFiles, f.int)
  of nkProcDef: decl(c, n[0], skProc)
  of nkFuncDef: decl(c, n[0], skFunc)
  of nkMethodDef: decl(c, n[0], skMethod)
  of nkIteratorDef: decl(c, n[0], skIterator)
  of nkConverterDef: decl(c, n[0], skConverter)
  of nkMacroDef: decl(c, n[0], skMacro)
  of nkTemplateDef: decl(c, n[0], skTemplate)
  of nkConstSection: declLoop(c, n, skConst)
  of nkLetSection: declLoop(c, n, skLet)
  of nkVarSection: declLoop(c, n, skVar)
  of nkUsingStmt: declLoop(c, n, skParam)
  of nkTypeSection:
    for a in n:
      decl(c, a[0], skType)
      for i in 1..<a.len:
        if a[i].kind == nkEnumTy:
          # declare enum members
          for b in a[i]:
            decl(c, b, skEnumField)
  else:
    discard "DO NOT recurse here."

proc semProcSignature(c: PContext; n: PNode; s: PSym) =
  # before compiling the proc params & body, set as current the scope
  # where the proc was declared

  # process parameters:
  # generic parameters, parameters, and also the implicit generic parameters
  # within are analysed. This is often the entirety of their semantic analysis
  # but later we will have to do a check for forward declarations, which can by
  # way of pragmas, default params, and so on invalidate this parsing.
  # Nonetheless, we need to carry out this analysis to perform the search for a
  # potential forward declaration.
  setGenericParamsMisc(c, n)

  if n[paramsPos].kind != nkEmpty:
    semParamList(c, n[paramsPos], n[genericParamsPos], s)
  else:
    s.typ = newProcType(c, n.info)

  if n[genericParamsPos].safeLen == 0:
    # if there exist no explicit or implicit generic parameters, then this is
    # at most a nullary generic (generic with no type params). Regardless of
    # whether it's a nullary generic or non-generic, we restore the original.
    # In the case of `nkEmpty` it's non-generic and an empty `nkGenericParams`
    # is a nullary generic.
    #
    # Remarks about nullary generics vs non-generics:
    # The difference between a non-generic and nullary generic is minor in
    # most cases but there are subtle and significant differences as well.
    # Due to instantiation that generic procs go through, a static echo in the
    # body of a nullary  generic will not be executed immediately, as it's
    # instantiated and not immediately evaluated.
    n[genericParamsPos] = n[miscPos][1]
    n[miscPos] = c.graph.emptyNode

  if tfTriggersCompileTime in s.typ.flags: incl(s.flags, sfCompileTime)
  if n[patternPos].kind != nkEmpty:
    n[patternPos] = semPattern(c, n[patternPos])
  if s.kind == skIterator:
    s.typ.flags.incl(tfIterator)
  elif s.kind == skFunc:
    incl(s.flags, sfNoSideEffect)
    incl(s.typ.flags, tfNoSideEffect)

proc addParametersAgainToCurrentScope(c: PContext; s: PSym) =
  for x in s.ast[genericParamsPos]:
    if x.kind == nkSym:
      addDecl(c, x.sym)
  for x in s.typ.n:
    if x.kind == nkSym:
      addParamOrResult(c, x.sym, s.kind)

proc semRoutineSignature(c: PContext; n: PNode; kind: TSymKind) =
  if n[namePos].kind == nkSym and n[namePos].sym.typ == nil:
    let s = n[namePos].sym
    pushOwner(c, s)
    openScope(c)
    semProcSignature(c, n, s)
    closeScope(c)
    popOwner(c)
    assert s.typ != nil

proc semLocalSignature(c: PContext; n: PNode; kind: TSymKind) =
  for i in 0..<n.len-2:
    discard "to do!"

proc semSignaturesAux(c: PContext, n: PNode) =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for i in 0..<n.len:
      semSignaturesAux(c, n[i])
  of nkProcDef: semRoutineSignature(c, n, skProc)
  of nkFuncDef: semRoutineSignature(c, n, skFunc)
  of nkMethodDef: semRoutineSignature(c, n, skMethod)
  of nkIteratorDef: semRoutineSignature(c, n, skIterator)
  of nkConverterDef: semRoutineSignature(c, n, skConverter)
  of nkMacroDef: semRoutineSignature(c, n, skMacro)
  of nkTemplateDef: semRoutineSignature(c, n, skTemplate)
  of nkConstSection: semLocalSignature(c, n, skConst)
  of nkLetSection: semLocalSignature(c, n, skLet)
  of nkVarSection: semLocalSignature(c, n, skVar)
  of nkUsingStmt: semLocalSignature(c, n, skParam)
  of nkTypeSection:
    typeSectionRightSidePass(c, n)
    typeSectionFinalPass(c, n)
  of nkImportStmt, nkFromStmt, nkImportExceptStmt:
    discard "TO DO!"
  else:
    discard "DO NOT recurse here."

proc semSignatures(c: PContext, n: PNode): PNode =
  result = topLevelDecl(c, n)
  semSignaturesAux(c, result)
