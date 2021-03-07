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
  intsets, ast, astalgo, msgs, options, idents, lookups,
  semdata, modulepaths, sigmatch, lineinfos, sets,
  modulegraphs

proc readExceptSet*(c: PContext, n: PNode): IntSet =
  assert n.kind in {nkImportExceptStmt, nkExportExceptStmt}
  result = initIntSet()
  for i in 1..<n.len:
    let ident = lookups.considerQuotedIdent(c, n[i])
    result.incl(ident.id)

proc declarePureEnumField*(c: PContext; s: PSym) =
  # XXX Remove the outer 'if' statement and see what breaks.
  var amb = false
  if someSymFromImportTable(c, s.name, amb) == nil:
    strTableAdd(c.pureEnumFields, s)
    when false:
      let checkB = strTableGet(c.pureEnumFields, s.name)
      if checkB == nil:
        strTableAdd(c.pureEnumFields, s)
    when false:
      # mark as ambiguous:
      incl(c.ambiguousSymbols, checkB.id)
      incl(c.ambiguousSymbols, s.id)

proc importPureEnumField(c: PContext; s: PSym) =
  var amb = false
  if someSymFromImportTable(c, s.name, amb) == nil:
    strTableAdd(c.pureEnumFields, s)
    when false:
      let checkB = strTableGet(c.pureEnumFields, s.name)
      if checkB == nil:
        strTableAdd(c.pureEnumFields, s)
    when false:
      # mark as ambiguous:
      incl(c.ambiguousSymbols, checkB.id)
      incl(c.ambiguousSymbols, s.id)

proc importPureEnumFields(c: PContext; s: PSym; etyp: PType) =
  assert sfPure in s.flags
  for j in 0..<etyp.n.len:
    var e = etyp.n[j].sym
    if e.kind != skEnumField:
      internalError(c.config, s.info, "rawImportSymbol")
      # BUGFIX: because of aliases for enums the symbol may already
      # have been put into the symbol table
      # BUGFIX: but only iff they are the same symbols!
    for check in importedItems(c, e.name):
      if check.id == e.id:
        e = nil
        break
    if e != nil:
      importPureEnumField(c, e)

proc rawImportSymbol(c: PContext, s, origin: PSym; importSet: var IntSet) =
  # This does not handle stubs, because otherwise loading on demand would be
  # pointless in practice. So importing stubs is fine here!
  # check if we have already a symbol of the same name:
  when false:
    var check = someSymFromImportTable(c, s.name)
    if check != nil and check.id != s.id:
      if s.kind notin OverloadableSyms or check.kind notin OverloadableSyms:
        # s and check need to be qualified:
        incl(c.ambiguousSymbols, s.id)
        incl(c.ambiguousSymbols, check.id)
  # thanks to 'export' feature, it could be we import the same symbol from
  # multiple sources, so we need to call 'strTableAdd' here:
  when false:
    # now lazy. Speeds up the compiler and is a prerequisite for IC.
    strTableAdd(c.importTable.symbols, s)
  else:
    importSet.incl s.id
  if s.kind == skType:
    var etyp = s.typ
    if etyp.kind in {tyBool, tyEnum}:
      for j in 0..<etyp.n.len:
        var e = etyp.n[j].sym
        if e.kind != skEnumField:
          internalError(c.config, s.info, "rawImportSymbol")
          # BUGFIX: because of aliases for enums the symbol may already
          # have been put into the symbol table
          # BUGFIX: but only iff they are the same symbols!
        for check in importedItems(c, e.name):
          if check.id == e.id:
            e = nil
            break
        if e != nil:
          if sfPure notin s.flags:
            rawImportSymbol(c, e, origin, importSet)
          else:
            importPureEnumField(c, e)
  else:
    if s.kind == skConverter: addConverter(c, LazySym(sym: s))
    if hasPattern(s): addPattern(c, LazySym(sym: s))
  if s.owner != origin:
    c.exportIndirections.incl((origin.id, s.id))

proc importSymbol(c: PContext, n: PNode, fromMod: PSym; importSet: var IntSet) =
  let ident = lookups.considerQuotedIdent(c, n)
  let s = someSym(c.graph, fromMod, ident)
  if s == nil:
    errorUndeclaredIdentifier(c, n.info, ident.s)
  else:
    when false:
      if s.kind == skStub: loadStub(s)
    let multiImport = s.kind notin ExportableSymKinds or s.kind in skProcKinds
    # for an enumeration we have to add all identifiers
    if multiImport:
      # for a overloadable syms add all overloaded routines
      var it: ModuleIter
      var e = initModuleIter(it, c.graph, fromMod, s.name)
      while e != nil:
        if e.name.id != s.name.id: internalError(c.config, n.info, "importSymbol: 3")
        if s.kind in ExportableSymKinds:
          rawImportSymbol(c, e, fromMod, importSet)
        e = nextModuleIter(it, c.graph)
    else:
      rawImportSymbol(c, s, fromMod, importSet)
    suggestSym(c.graph, n.info, s, c.graph.usageSym, false)

proc addImport(c: PContext; im: sink ImportedModule) =
  for i in 0..high(c.imports):
    if c.imports[i].m == im.m:
      # we have already imported the module: Check which import
      # is more "powerful":
      case c.imports[i].mode
      of importAll: discard "already imported all symbols"
      of importSet:
        case im.mode
        of importAll, importExcept:
          # XXX: slightly wrong semantics for 'importExcept'...
          # But we should probably change the spec and disallow this case.
          c.imports[i] = im
        of importSet:
          # merge the import sets:
          c.imports[i].imported.incl im.imported
      of importExcept:
        case im.mode
        of importAll:
          c.imports[i] = im
        of importSet:
          discard
        of importExcept:
          var cut = initIntSet()
          # only exclude what is consistent between the two sets:
          for j in im.exceptSet:
            if j in c.imports[i].exceptSet:
              cut.incl j
          c.imports[i].exceptSet = cut
      return
  c.imports.add im

template addUnnamedIt(c: PContext, fromMod: PSym; filter: untyped) {.dirty.} =
  for it in c.graph.ifaces[fromMod.position].converters:
    if filter:
      addConverter(c, it)
  for it in c.graph.ifaces[fromMod.position].patterns:
    if filter:
      addPattern(c, it)
  for it in c.graph.ifaces[fromMod.position].pureEnums:
    if filter:
      importPureEnumFields(c, it.sym, it.sym.typ)

proc importAllSymbolsExcept(c: PContext, fromMod: PSym, exceptSet: IntSet) =
  c.addImport ImportedModule(m: fromMod, mode: importExcept, exceptSet: exceptSet)
  addUnnamedIt(c, fromMod, it.sym.id notin exceptSet)

proc importAllSymbols*(c: PContext, fromMod: PSym) =
  c.addImport ImportedModule(m: fromMod, mode: importAll)
  addUnnamedIt(c, fromMod, true)
  when false:
    var exceptSet: IntSet
    importAllSymbolsExcept(c, fromMod, exceptSet)

proc importForwarded(c: PContext, n: PNode, exceptSet: IntSet; fromMod: PSym; importSet: var IntSet) =
  if n.isNil: return
  case n.kind
  of nkExportStmt:
    for a in n:
      assert a.kind == nkSym
      let s = a.sym
      if s.kind == skModule:
        importAllSymbolsExcept(c, s, exceptSet)
      elif exceptSet.isNil or s.name.id notin exceptSet:
        rawImportSymbol(c, s, fromMod, importSet)
  of nkExportExceptStmt:
    localError(c.config, n.info, "'export except' not implemented")
  else:
    for i in 0..n.safeLen-1:
      importForwarded(c, n[i], exceptSet, fromMod, importSet)

proc importModuleAs(c: PContext; n: PNode, realModule: PSym): PSym =
  result = realModule
  c.unusedImports.add((realModule, n.info))
  if n.kind != nkImportAs: discard
  elif n.len != 2 or n[1].kind != nkIdent:
    localError(c.config, n.info, "module alias must be an identifier")
  elif n[1].ident.id != realModule.name.id:
    # some misguided guy will write 'import abc.foo as foo' ...
    result = createModuleAlias(realModule, nextSymId c.idgen, n[1].ident, realModule.info,
                               c.config.options)

proc myImportModule(c: PContext, n: PNode; importStmtResult: PNode): PSym =
  let f = checkModuleName(c.config, n)
  if f != InvalidFileIdx:
    addImportFileDep(c, f)
    let L = c.graph.importStack.len
    let recursion = c.graph.importStack.find(f)
    c.graph.importStack.add f
    #echo "adding ", toFullPath(f), " at ", L+1
    if recursion >= 0:
      var err = ""
      for i in recursion..<L:
        if i > recursion: err.add "\n"
        err.add toFullPath(c.config, c.graph.importStack[i]) & " imports " &
                toFullPath(c.config, c.graph.importStack[i+1])
      c.recursiveDep = err

    discard pushOptionEntry(c)
    result = importModuleAs(c, n, c.graph.importModuleCallback(c.graph, c.module, f))
    popOptionEntry(c)

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
    suggestSym(c.graph, n.info, result, c.graph.usageSym, false)
    importStmtResult.add newSymNode(result, n.info)
    #newStrNode(toFullPath(c.config, f), n.info)

proc transformImportAs(c: PContext; n: PNode): PNode =
  if n.kind == nkInfix and considerQuotedIdent(c, n[0]).s == "as":
    result = newNodeI(nkImportAs, n.info)
    result.add n[1]
    result.add n[2]
  else:
    result = n

proc impMod(c: PContext; it: PNode; importStmtResult: PNode) =
  let it = transformImportAs(c, it)
  let m = myImportModule(c, it, importStmtResult)
  if m != nil:
    # ``addDecl`` needs to be done before ``importAllSymbols``!
    addDecl(c, m, it.info) # add symbol to symbol table of module
    importAllSymbols(c, m)
    #importForwarded(c, m.ast, emptySet, m)

proc evalImport*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  for i in 0..<n.len:
    let it = n[i]
    if it.kind == nkInfix and it.len == 3 and it[2].kind == nkBracket:
      let sep = it[0]
      let dir = it[1]
      var imp = newNodeI(nkInfix, it.info)
      imp.add sep
      imp.add dir
      imp.add sep # dummy entry, replaced in the loop
      for x in it[2]:
        # transform `a/b/[c as d]` to `/a/b/c as d`
        if x.kind == nkInfix and x[0].ident.s == "as":
          let impAs = copyTree(x)
          imp[2] = x[1]
          impAs[1] = imp
          impMod(c, imp, result)
        else:
          imp[2] = x
          impMod(c, imp, result)
    else:
      impMod(c, it, result)

proc evalFrom*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  checkMinSonsLen(n, 2, c.config)
  n[0] = transformImportAs(c, n[0])
  var m = myImportModule(c, n[0], result)
  if m != nil:
    n[0] = newSymNode(m)
    addDecl(c, m, n.info)               # add symbol to symbol table of module

    var im = ImportedModule(m: m, mode: importSet, imported: initIntSet())
    for i in 1..<n.len:
      if n[i].kind != nkNilLit:
        importSymbol(c, n[i], m, im.imported)
    c.addImport im

proc evalImportExcept*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkImportStmt, n.info)
  checkMinSonsLen(n, 2, c.config)
  n[0] = transformImportAs(c, n[0])
  var m = myImportModule(c, n[0], result)
  if m != nil:
    n[0] = newSymNode(m)
    addDecl(c, m, n.info)               # add symbol to symbol table of module
    importAllSymbolsExcept(c, m, readExceptSet(c, n))
    #importForwarded(c, m.ast, exceptSet, m)
