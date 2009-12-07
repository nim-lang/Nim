#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the symbol importing mechanism.

import 
  strutils, os, ast, astalgo, msgs, options, idents, rodread, lookups, semdata, 
  passes

proc evalImport*(c: PContext, n: PNode): PNode
proc evalFrom*(c: PContext, n: PNode): PNode
proc importAllSymbols*(c: PContext, fromMod: PSym)
proc getModuleFile*(n: PNode): string
# implementation

proc findModule(info: TLineInfo, modulename: string): string = 
  # returns path to module
  result = options.FindFile(AddFileExt(modulename, nimExt))
  if result == "": liMessage(info, errCannotOpenFile, modulename)
  
proc getModuleFile(n: PNode): string = 
  case n.kind
  of nkStrLit, nkRStrLit, nkTripleStrLit: 
    result = findModule(n.info, UnixToNativePath(n.strVal))
  of nkIdent: 
    result = findModule(n.info, n.ident.s)
  of nkSym: 
    result = findModule(n.info, n.sym.name.s)
  else: 
    internalError(n.info, "getModuleFile()")
    result = ""

proc rawImportSymbol(c: PContext, s: PSym) = 
  var 
    check, copy, e: PSym
    etyp: PType               # enumeration type
    it: TIdentIter
  # This does not handle stubs, because otherwise loading on demand would be
  # pointless in practice. So importing stubs is fine here!
  copy = s # do not copy symbols when importing!
  # check if we have already a symbol of the same name:
  check = StrTableGet(c.tab.stack[importTablePos], s.name)
  if (check != nil) and (check.id != copy.id): 
    if not (s.kind in OverloadableSyms): 
      # s and check need to be qualified:
      IntSetIncl(c.AmbiguousSymbols, copy.id)
      IntSetIncl(c.AmbiguousSymbols, check.id)
  StrTableAdd(c.tab.stack[importTablePos], copy)
  if s.kind == skType: 
    etyp = s.typ
    if etyp.kind in {tyBool, tyEnum}: 
      for j in countup(0, sonsLen(etyp.n) - 1): 
        e = etyp.n.sons[j].sym
        if (e.Kind != skEnumField): 
          InternalError(s.info, "rawImportSymbol") 
          # BUGFIX: because of aliases for enums the symbol may already
          # have been put into the symbol table
          # BUGFIX: but only iff they are the same symbols!
        check = InitIdentIter(it, c.tab.stack[importTablePos], e.name)
        while check != nil: 
          if check.id == e.id: 
            e = nil
            break 
          check = NextIdentIter(it, c.tab.stack[importTablePos])
        if e != nil: 
          rawImportSymbol(c, e)
  elif s.kind == skConverter: 
    addConverter(c, s)        # rodgen assures that converters are no stubs
  
proc importSymbol(c: PContext, ident: PNode, fromMod: PSym) = 
  var 
    s, e: PSym
    it: TIdentIter
  if (ident.kind != nkIdent): InternalError(ident.info, "importSymbol")
  s = StrTableGet(fromMod.tab, ident.ident)
  if s == nil: liMessage(ident.info, errUndeclaredIdentifier, ident.ident.s)
  if s.kind == skStub: loadStub(s)
  if not (s.Kind in ExportableSymKinds): 
    InternalError(ident.info, "importSymbol: 2")  
  # for an enumeration we have to add all identifiers
  case s.Kind
  of skProc, skMethod, skIterator, skMacro, skTemplate, skConverter: 
    # for a overloadable syms add all overloaded routines
    e = InitIdentIter(it, fromMod.tab, s.name)
    while e != nil: 
      if (e.name.id != s.Name.id): InternalError(ident.info, "importSymbol: 3")
      rawImportSymbol(c, e)
      e = NextIdentIter(it, fromMod.tab)
  else: rawImportSymbol(c, s)
  
proc importAllSymbols(c: PContext, fromMod: PSym) = 
  var i: TTabIter
  var s = InitTabIter(i, fromMod.tab)
  while s != nil: 
    if s.kind != skModule: 
      if s.kind != skEnumField: 
        if not (s.Kind in ExportableSymKinds): 
          InternalError(s.info, "importAllSymbols: " & $s.kind)
        rawImportSymbol(c, s) # this is correct!
    s = NextIter(i, fromMod.tab)

proc evalImport(c: PContext, n: PNode): PNode = 
  result = n
  for i in countup(0, sonsLen(n) - 1): 
    var f = getModuleFile(n.sons[i])
    var m = gImportModule(f)
    if sfDeprecated in m.flags: 
      liMessage(n.sons[i].info, warnDeprecated, m.name.s) 
    # ``addDecl`` needs to be done before ``importAllSymbols``!
    addDecl(c, m)             # add symbol to symbol table of module
    importAllSymbols(c, m)

proc evalFrom(c: PContext, n: PNode): PNode = 
  result = n
  checkMinSonsLen(n, 2)
  var f = getModuleFile(n.sons[0])
  var m = gImportModule(f)
  n.sons[0] = newSymNode(m)
  addDecl(c, m)               # add symbol to symbol table of module
  for i in countup(1, sonsLen(n) - 1): importSymbol(c, n.sons[i], m)
  
