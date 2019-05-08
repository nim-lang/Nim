#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the symbol importing mechanism.

import
  intsets, strutils, os, ast, astalgo, msgs, options, idents, lookups,
  semdata, passes, renderer, modulepaths, sigmatch, lineinfos

proc readExceptSet*(c: PContext, n: PNode): IntSet =
  assert n.kind in {nkImportExceptStmt, nkExportExceptStmt}
  result = initIntSet()
  for i in 1 ..< n.len:
    let ident = lookups.considerQuotedIdent(c, n[i])
    result.incl(ident.id)

proc importPureEnumField*(c: PContext; s: PSym) =
  let check = strTableGet(c.importTable.symbols, s.name)
  if check == nil:
    let checkB = strTableGet(c.pureEnumFields, s.name)
    if checkB == nil:
      strTableAdd(c.pureEnumFields, s)
    else:
      # mark as ambigous:
      incl(c.ambiguousSymbols, checkB.id)
      incl(c.ambiguousSymbols, s.id)

proc rawImportSymbol(c: PContext, s: PSym) =
  # This does not handle stubs, because otherwise loading on demand would be
  # pointless in practice. So importing stubs is fine here!
  # check if we have already a symbol of the same name:
  var check = strTableGet(c.importTable.symbols, s.name)
  if check != nil and check.id != s.id:
    if s.kind notin OverloadableSyms or check.kind notin OverloadableSyms:
      # s and check need to be qualified:
      incl(c.ambiguousSymbols, s.id)
      incl(c.ambiguousSymbols, check.id)
  # thanks to 'export' feature, it could be we import the same symbol from
  # multiple sources, so we need to call 'StrTableAdd' here:
  strTableAdd(c.importTable.symbols, s)
  if s.kind == skType:
    var etyp = s.typ
    if etyp.kind in {tyBool, tyEnum}:
      for j in 0 ..< sonsLen(etyp.n):
        var e = etyp.n.sons[j].sym
        if e.kind != skEnumField:
          internalError(c.config, s.info, "rawImportSymbol")
          # BUGFIX: because of aliases for enums the symbol may already
          # have been put into the symbol table
          # BUGFIX: but only iff they are the same symbols!
        var it: TIdentIter
        check = initIdentIter(it, c.importTable.symbols, e.name)
        while check != nil:
          if check.id == e.id:
            e = nil
            break
          check = nextIdentIter(it, c.importTable.symbols)
        if e != nil:
          if sfPure notin s.flags:
            rawImportSymbol(c, e)
          else:
            importPureEnumField(c, e)
  else:
    # rodgen assures that converters and patterns are no stubs
    if s.kind == skConverter: addConverter(c, s)
    if hasPattern(s): addPattern(c, s)

proc importSymbol(c: PContext, n: PNode, fromMod: PSym) =
  let ident = lookups.considerQuotedIdent(c, n)
  let s = strTableGet(fromMod.tab, ident)
  if s == nil:
    errorUndeclaredIdentifier(c, n.info, ident.s)
  else:
    when false:
      if s.kind == skStub: loadStub(s)
    if s.kind notin ExportableSymKinds:
      internalError(c.config, n.info, "importSymbol: 2")
    # for an enumeration we have to add all identifiers
    case s.kind
    of skProcKinds:
      # for a overloadable syms add all overloaded routines
      var it: TIdentIter
      var e = initIdentIter(it, fromMod.tab, s.name)
      while e != nil:
        if e.name.id != s.name.id: internalError(c.config, n.info, "importSymbol: 3")
        rawImportSymbol(c, e)
        e = nextIdentIter(it, fromMod.tab)
    else: rawImportSymbol(c, s)
    suggestSym(c.config, n.info, s, c.graph.usageSym, false)

proc importAllSymbolsExcept(c: PContext, fromMod: PSym, exceptSet: IntSet) =
  var i: TTabIter
  var s = initTabIter(i, fromMod.tab)
  while s != nil:
    if s.kind != skModule:
      if s.kind != skEnumField:
        if s.kind notin ExportableSymKinds:
          internalError(c.config, s.info, "importAllSymbols: " & $s.kind & " " & s.name.s)
        if exceptSet.isNil or s.name.id notin exceptSet:
          rawImportSymbol(c, s)
    s = nextIter(i, fromMod.tab)

proc importAllSymbols*(c: PContext, fromMod: PSym) =
  var exceptSet: IntSet
  importAllSymbolsExcept(c, fromMod, exceptSet)

proc importForwarded(c: PContext, n: PNode, exceptSet: IntSet) =
  if n.isNil: return
  case n.kind
  of nkExportStmt:
    for a in n:
      assert a.kind == nkSym
      let s = a.sym
      if s.kind == skModule:
        importAllSymbolsExcept(c, s, exceptSet)
      elif exceptSet.isNil or s.name.id notin exceptSet:
        rawImportSymbol(c, s)
  of nkExportExceptStmt:
    localError(c.config, n.info, "'export except' not implemented")
  else:
    for i in 0..safeLen(n)-1:
      importForwarded(c, n.sons[i], exceptSet)

proc importModuleAs(c: PContext; n: PNode, realModule: PSym): PSym =
  result = realModule
  if n.kind != nkImportAs: discard
  elif n.len != 2 or n.sons[1].kind != nkIdent:
    localError(c.config, n.info, "module alias must be an identifier")
  elif n.sons[1].ident.id != realModule.name.id:
    # some misguided guy will write 'import abc.foo as foo' ...
    result = createModuleAlias(realModule, n.sons[1].ident, realModule.info,
                               c.config.options)

proc myImportModule(c: PContext, n: PNode; importStmtResult: PNode): PSym =
  let f = checkModuleName(c.config, n)
  if f != InvalidFileIDX:
    let L = c.graph.importStack.len
    let recursion = c.graph.importStack.find(f)
    c.graph.importStack.add f
    #echo "adding ", toFullPath(f), " at ", L+1
    if recursion >= 0:
      var err = ""
      for i in recursion ..< L:
        if i > recursion: err.add "\n"
        err.add toFullPath(c.config, c.graph.importStack[i]) & " imports " &
                toFullPath(c.config, c.graph.importStack[i+1])
      c.recursiveDep = err
    result = importModuleAs(c, n, c.graph.importModuleCallback(c.graph, c.module, f))
    #echo "set back to ", L
    c.graph.importStack.setLen(L)
    # we cannot perform this check reliably because of
    # test: modules/import_in_config)
    when true:
      if result.info.fileIndex == c.module.info.fileIndex and
          result.info.fileIndex == n.info.fileIndex:
        localError(c.config, n.info, "A module cannot import itself")
    if sfDeprecated in result.flags:
      if result.constraint != nil:
        message(c.config, n.info, warnDeprecated, result.constraint.strVal & "; " & result.name.s & " is deprecated")
      else:
        message(c.config, n.info, warnDeprecated, result.name.s & " is deprecated")
    suggestSym(c.config, n.info, result, c.graph.usageSym, false)
    importStmtResult.add newSymNode(result, n.info)
    #newStrNode(toFullPath(c.config, f), n.info)

proc transformImportAs(c: PContext; n: PNode): PNode =
  if n.kind == nkInfix and considerQuotedIdent(c, n[0]).s == "as":
    result = newNodeI(nkImportAs, n.info)
    result.add n.sons[1]
    result.add n.sons[2]
  else:
    result = n

proc impMod(c: PContext; it: PNode; importStmtResult: PNode) =
  let it = transformImportAs(c, it)
  let m = myImportModule(c, it, importStmtResult)
  if m != nil:
    var emptySet: IntSet
    # ``addDecl`` needs to be done before ``importAllSymbols``!
    addDecl(c, m, it.info) # add symbol to symbol table of module
    importAllSymbolsExcept(c, m, emptySet)
    #importForwarded(c, m.ast, emptySet)

proc evalImport*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  for i in 0 ..< sonsLen(n):
    let it = n.sons[i]
    if it.kind == nkInfix and it.len == 3 and it[2].kind == nkBracket:
      let sep = it[0]
      let dir = it[1]
      var imp = newNodeI(nkInfix, it.info)
      imp.add sep
      imp.add dir
      imp.add sep # dummy entry, replaced in the loop
      for x in it[2]:
        # transform `a/b/[c as d]` to `/a/b/c as d`
        if x.kind == nkInfix and x.sons[0].ident.s == "as":
          let impAs = copyTree(x)
          imp.sons[2] = x.sons[1]
          impAs.sons[1] = imp
          impMod(c, imp, result)
        else:
          imp.sons[2] = x
          impMod(c, imp, result)
    else:
      impMod(c, it, result)

proc evalFrom*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  checkMinSonsLen(n, 2, c.config)
  n.sons[0] = transformImportAs(c, n.sons[0])
  var m = myImportModule(c, n.sons[0], result)
  if m != nil:
    n.sons[0] = newSymNode(m)
    addDecl(c, m, n.info)               # add symbol to symbol table of module
    for i in 1 ..< sonsLen(n):
      if n.sons[i].kind != nkNilLit:
        importSymbol(c, n.sons[i], m)

proc evalImportExcept*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  checkMinSonsLen(n, 2, c.config)
  n.sons[0] = transformImportAs(c, n.sons[0])
  var m = myImportModule(c, n.sons[0], result)
  if m != nil:
    n.sons[0] = newSymNode(m)
    addDecl(c, m, n.info)               # add symbol to symbol table of module
    importAllSymbolsExcept(c, m, readExceptSet(c, n))
    #importForwarded(c, m.ast, exceptSet)
