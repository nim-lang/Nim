#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements lookup helpers.

import 
  ast, astalgo, idents, semdata, types, msgs, options, rodread, rnimsyn

type 
  TOverloadIterMode* = enum 
    oimDone, oimNoQualifier, oimSelfModule, oimOtherModule, oimSymChoice
  TOverloadIter*{.final.} = object 
    stackPtr*: int
    it*: TIdentIter
    m*: PSym
    mode*: TOverloadIterMode

proc getSymRepr*(s: PSym): string = 
  case s.kind
  of skProc, skMethod, skConverter, skIterator: result = getProcHeader(s)
  else: result = s.name.s
  
proc CloseScope*(tab: var TSymTab) = 
  var 
    it: TTabIter
    s: PSym
  # check if all symbols have been used and defined:
  if (tab.tos > len(tab.stack)): InternalError("CloseScope")
  s = InitTabIter(it, tab.stack[tab.tos - 1])
  while s != nil: 
    if sfForward in s.flags: 
      LocalError(s.info, errImplOfXexpected, getSymRepr(s))
    elif ({sfUsed, sfInInterface} * s.flags == {}) and
        (optHints in s.options): # BUGFIX: check options in s!
      if not (s.kind in {skForVar, skParam, skMethod, skUnknown}): 
        Message(s.info, hintXDeclaredButNotUsed, getSymRepr(s))
    s = NextIter(it, tab.stack[tab.tos - 1])
  astalgo.rawCloseScope(tab)

proc AddSym*(t: var TStrTable, n: PSym) = 
  if StrTableIncl(t, n): LocalError(n.info, errAttemptToRedefine, n.name.s)
  
proc addDecl*(c: PContext, sym: PSym) = 
  if SymTabAddUnique(c.tab, sym) == Failure: 
    LocalError(sym.info, errAttemptToRedefine, sym.Name.s)
  
proc addDeclAt*(c: PContext, sym: PSym, at: Natural) = 
  if SymTabAddUniqueAt(c.tab, sym, at) == Failure: 
    LocalError(sym.info, errAttemptToRedefine, sym.Name.s)

proc AddInterfaceDeclAux(c: PContext, sym: PSym) = 
  if (sfInInterface in sym.flags): 
    # add to interface:
    if c.module == nil: InternalError(sym.info, "AddInterfaceDeclAux")
    StrTableAdd(c.module.tab, sym)
  if getCurrOwner().kind == skModule: incl(sym.flags, sfGlobal)

proc addInterfaceDeclAt*(c: PContext, sym: PSym, at: Natural) = 
  addDeclAt(c, sym, at)
  AddInterfaceDeclAux(c, sym)
  
proc addOverloadableSymAt*(c: PContext, fn: PSym, at: Natural) = 
  if fn.kind notin OverloadableSyms: 
    InternalError(fn.info, "addOverloadableSymAt")
  var check = StrTableGet(c.tab.stack[at], fn.name)
  if check != nil and check.Kind notin OverloadableSyms: 
    LocalError(fn.info, errAttemptToRedefine, fn.Name.s)
  else:
    SymTabAddAt(c.tab, fn, at)
  
proc addInterfaceDecl*(c: PContext, sym: PSym) = 
  # it adds the symbol to the interface if appropriate
  addDecl(c, sym)
  AddInterfaceDeclAux(c, sym)

proc addInterfaceOverloadableSymAt*(c: PContext, sym: PSym, at: int) = 
  # it adds the symbol to the interface if appropriate
  addOverloadableSymAt(c, sym, at)
  AddInterfaceDeclAux(c, sym)

proc lookUp*(c: PContext, n: PNode): PSym = 
  # Looks up a symbol. Generates an error in case of nil.
  case n.kind
  of nkAccQuoted: 
    result = lookup(c, n.sons[0])
  of nkSym: 
    result = n.sym
  of nkIdent: 
    result = SymtabGet(c.Tab, n.ident)
    if result == nil: GlobalError(n.info, errUndeclaredIdentifier, n.ident.s)
  else: InternalError(n.info, "lookUp")
  if IntSetContains(c.AmbiguousSymbols, result.id): 
    LocalError(n.info, errUseQualifier, result.name.s)
  if result.kind == skStub: loadStub(result)
  
type 
  TLookupFlag* = enum 
    checkAmbiguity, checkUndeclared
  
proc QualifiedLookUp*(c: PContext, n: PNode, flags = {checkUndeclared}): PSym = 
  case n.kind
  of nkIdent: 
    result = SymtabGet(c.Tab, n.ident)
    if result == nil and checkUndeclared in flags: 
      GlobalError(n.info, errUndeclaredIdentifier, n.ident.s)
    elif checkAmbiguity in flags and result != nil and 
        IntSetContains(c.AmbiguousSymbols, result.id): 
      LocalError(n.info, errUseQualifier, n.ident.s)
  of nkSym: 
    result = n.sym
    if checkAmbiguity in flags and IntSetContains(c.AmbiguousSymbols, 
                                                  result.id): 
      LocalError(n.info, errUseQualifier, n.sym.name.s)
  of nkDotExpr: 
    result = nil
    var m = qualifiedLookUp(c, n.sons[0], flags*{checkUndeclared})
    if (m != nil) and (m.kind == skModule): 
      var ident: PIdent = nil
      if (n.sons[1].kind == nkIdent): 
        ident = n.sons[1].ident
      elif (n.sons[1].kind == nkAccQuoted) and
          (n.sons[1].sons[0].kind == nkIdent): 
        ident = n.sons[1].sons[0].ident
      if ident != nil: 
        if m == c.module: 
          result = StrTableGet(c.tab.stack[ModuleTablePos], ident)
        else: 
          result = StrTableGet(m.tab, ident)
        if result == nil and checkUndeclared in flags: 
          GlobalError(n.sons[1].info, errUndeclaredIdentifier, ident.s)
      elif checkUndeclared in flags: 
        GlobalError(n.sons[1].info, errIdentifierExpected, 
                    renderTree(n.sons[1]))
  of nkAccQuoted: 
    result = QualifiedLookup(c, n.sons[0], flags)
  else: 
    result = nil
  if (result != nil) and (result.kind == skStub): loadStub(result)
  
proc InitOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym = 
  result = nil
  case n.kind
  of nkIdent: 
    o.stackPtr = c.tab.tos
    o.mode = oimNoQualifier
    while (result == nil): 
      dec(o.stackPtr)
      if o.stackPtr < 0: break 
      result = InitIdentIter(o.it, c.tab.stack[o.stackPtr], n.ident)
  of nkSym: 
    result = n.sym
    o.mode = oimDone
  of nkDotExpr: 
    o.mode = oimOtherModule
    o.m = qualifiedLookUp(c, n.sons[0])
    if (o.m != nil) and (o.m.kind == skModule): 
      var ident: PIdent = nil
      if (n.sons[1].kind == nkIdent): 
        ident = n.sons[1].ident
      elif (n.sons[1].kind == nkAccQuoted) and
          (n.sons[1].sons[0].kind == nkIdent): 
        ident = n.sons[1].sons[0].ident
      if ident != nil: 
        if o.m == c.module: 
          # a module may access its private members:
          result = InitIdentIter(o.it, c.tab.stack[ModuleTablePos], ident)
          o.mode = oimSelfModule
        else: 
          result = InitIdentIter(o.it, o.m.tab, ident)
      else: 
        GlobalError(n.sons[1].info, errIdentifierExpected, 
                    renderTree(n.sons[1]))
  of nkAccQuoted: 
    result = InitOverloadIter(o, c, n.sons[0])
  of nkSymChoice: 
    o.mode = oimSymChoice
    result = n.sons[0].sym
    o.stackPtr = 1
  else: 
    nil
  if (result != nil) and (result.kind == skStub): loadStub(result)
  
proc nextOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym = 
  case o.mode
  of oimDone: 
    result = nil
  of oimNoQualifier: 
    if n.kind == nkAccQuoted: 
      result = nextOverloadIter(o, c, n.sons[0]) # BUGFIX
    elif o.stackPtr >= 0: 
      result = nextIdentIter(o.it, c.tab.stack[o.stackPtr])
      while (result == nil): 
        dec(o.stackPtr)
        if o.stackPtr < 0: break 
        result = InitIdentIter(o.it, c.tab.stack[o.stackPtr], o.it.name) 
        # BUGFIX: o.it.name <-> n.ident
    else: 
      result = nil
  of oimSelfModule: 
    result = nextIdentIter(o.it, c.tab.stack[ModuleTablePos])
  of oimOtherModule: 
    result = nextIdentIter(o.it, o.m.tab)
  of oimSymChoice: 
    if o.stackPtr < sonsLen(n): 
      result = n.sons[o.stackPtr].sym
      inc(o.stackPtr)
    else: 
      result = nil
  if (result != nil) and (result.kind == skStub): loadStub(result)
  
