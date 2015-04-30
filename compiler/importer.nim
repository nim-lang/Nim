#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the symbol importing mechanism.

import
  intsets, strutils, os, ast, astalgo, msgs, options, idents, rodread, lookups,
  semdata, passes, renderer

proc evalImport*(c: PContext, n: PNode): PNode
proc evalFrom*(c: PContext, n: PNode): PNode

proc getModuleName*(n: PNode): string =
  # This returns a short relative module name without the nim extension
  # e.g. like "system", "importer" or "somepath/module"
  # The proc won't perform any checks that the path is actually valid
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    result = unixToNativePath(n.strVal)
  of nkIdent:
    result = n.ident.s
  of nkSym:
    result = n.sym.name.s
  of nkInfix, nkPrefix:
    if n.sons[0].kind == nkIdent and n.sons[0].ident.id == getIdent("as").id:
      # XXX hack ahead:
      n.kind = nkImportAs
      n.sons[0] = n.sons[1]
      n.sons[1] = n.sons[2]
      n.sons.setLen(2)
      return getModuleName(n.sons[0])
    # hacky way to implement 'x / y /../ z':
    result = renderTree(n, {renderNoComments}).replace(" ")
  of nkDotExpr:
    result = renderTree(n, {renderNoComments}).replace(".", "/")
  of nkImportAs:
    result = getModuleName(n.sons[0])
  else:
    localError(n.info, errGenerated, "invalid module name: '$1'" % n.renderTree)
    result = ""

proc checkModuleName*(n: PNode): int32 =
  # This returns the full canonical path for a given module import
  let modulename = n.getModuleName
  let fullPath = findModule(modulename, n.info.toFullPath)
  if fullPath.len == 0:
    localError(n.info, errCannotOpenFile, modulename)
    result = InvalidFileIDX
  else:
    result = fullPath.fileInfoIdx

proc rawImportSymbol(c: PContext, s: PSym) =
  # This does not handle stubs, because otherwise loading on demand would be
  # pointless in practice. So importing stubs is fine here!
  # check if we have already a symbol of the same name:
  var check = strTableGet(c.importTable.symbols, s.name)
  if check != nil and check.id != s.id:
    if s.kind notin OverloadableSyms:
      # s and check need to be qualified:
      incl(c.ambiguousSymbols, s.id)
      incl(c.ambiguousSymbols, check.id)
  # thanks to 'export' feature, it could be we import the same symbol from
  # multiple sources, so we need to call 'StrTableAdd' here:
  strTableAdd(c.importTable.symbols, s)
  if s.kind == skType:
    var etyp = s.typ
    if etyp.kind in {tyBool, tyEnum} and sfPure notin s.flags:
      for j in countup(0, sonsLen(etyp.n) - 1):
        var e = etyp.n.sons[j].sym
        if e.kind != skEnumField:
          internalError(s.info, "rawImportSymbol")
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
          rawImportSymbol(c, e)
  else:
    # rodgen assures that converters and patterns are no stubs
    if s.kind == skConverter: addConverter(c, s)
    if hasPattern(s): addPattern(c, s)

proc importSymbol(c: PContext, n: PNode, fromMod: PSym) =
  let ident = lookups.considerQuotedIdent(n)
  let s = strTableGet(fromMod.tab, ident)
  if s == nil:
    localError(n.info, errUndeclaredIdentifier, ident.s)
  else:
    if s.kind == skStub: loadStub(s)
    if s.kind notin ExportableSymKinds:
      internalError(n.info, "importSymbol: 2")
    # for an enumeration we have to add all identifiers
    case s.kind
    of skProcKinds:
      # for a overloadable syms add all overloaded routines
      var it: TIdentIter
      var e = initIdentIter(it, fromMod.tab, s.name)
      while e != nil:
        if e.name.id != s.name.id: internalError(n.info, "importSymbol: 3")
        rawImportSymbol(c, e)
        e = nextIdentIter(it, fromMod.tab)
    else: rawImportSymbol(c, s)

proc importAllSymbolsExcept(c: PContext, fromMod: PSym, exceptSet: IntSet) =
  var i: TTabIter
  var s = initTabIter(i, fromMod.tab)
  while s != nil:
    if s.kind != skModule:
      if s.kind != skEnumField:
        if s.kind notin ExportableSymKinds:
          internalError(s.info, "importAllSymbols: " & $s.kind)
        if exceptSet.empty or s.name.id notin exceptSet:
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
      elif exceptSet.empty or s.name.id notin exceptSet:
        rawImportSymbol(c, s)
  of nkExportExceptStmt:
    localError(n.info, errGenerated, "'export except' not implemented")
  else:
    for i in 0..safeLen(n)-1:
      importForwarded(c, n.sons[i], exceptSet)

proc importModuleAs(n: PNode, realModule: PSym): PSym =
  result = realModule
  if n.kind != nkImportAs: discard
  elif n.len != 2 or n.sons[1].kind != nkIdent:
    localError(n.info, errGenerated, "module alias must be an identifier")
  elif n.sons[1].ident.id != realModule.name.id:
    # some misguided guy will write 'import abc.foo as foo' ...
    result = createModuleAlias(realModule, n.sons[1].ident, realModule.info)

proc myImportModule(c: PContext, n: PNode): PSym =
  var f = checkModuleName(n)
  if f != InvalidFileIDX:
    result = importModuleAs(n, gImportModule(c.module, f))
    if result.info.fileIndex == n.info.fileIndex:
      localError(n.info, errGenerated, "A module cannot import itself")
    if sfDeprecated in result.flags:
      message(n.info, warnDeprecated, result.name.s)

proc evalImport(c: PContext, n: PNode): PNode =
  result = n
  var emptySet: IntSet
  for i in countup(0, sonsLen(n) - 1):
    var m = myImportModule(c, n.sons[i])
    if m != nil:
      # ``addDecl`` needs to be done before ``importAllSymbols``!
      addDecl(c, m)             # add symbol to symbol table of module
      importAllSymbolsExcept(c, m, emptySet)
      #importForwarded(c, m.ast, emptySet)

proc evalFrom(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 2)
  var m = myImportModule(c, n.sons[0])
  if m != nil:
    n.sons[0] = newSymNode(m)
    addDecl(c, m)               # add symbol to symbol table of module
    for i in countup(1, sonsLen(n) - 1):
      if n.sons[i].kind != nkNilLit:
        importSymbol(c, n.sons[i], m)

proc evalImportExcept*(c: PContext, n: PNode): PNode =
  result = n
  checkMinSonsLen(n, 2)
  var m = myImportModule(c, n.sons[0])
  if m != nil:
    n.sons[0] = newSymNode(m)
    addDecl(c, m)               # add symbol to symbol table of module
    var exceptSet = initIntSet()
    for i in countup(1, sonsLen(n) - 1):
      let ident = lookups.considerQuotedIdent(n.sons[i])
      exceptSet.incl(ident.id)
    importAllSymbolsExcept(c, m, exceptSet)
    #importForwarded(c, m.ast, exceptSet)
