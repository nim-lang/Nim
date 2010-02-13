#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
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


proc getSymRepr*(s: PSym): string
proc CloseScope*(tab: var TSymTab)
proc AddSym*(t: var TStrTable, n: PSym)
proc addDecl*(c: PContext, sym: PSym)
proc addDeclAt*(c: PContext, sym: PSym, at: Natural)
proc addOverloadableSymAt*(c: PContext, fn: PSym, at: Natural)
proc addInterfaceDecl*(c: PContext, sym: PSym)
proc addInterfaceOverloadableSymAt*(c: PContext, sym: PSym, at: int)
proc lookUp*(c: PContext, n: PNode): PSym
  # Looks up a symbol. Generates an error in case of nil.
proc QualifiedLookUp*(c: PContext, n: PNode, ambiguousCheck: bool): PSym
proc InitOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym
proc nextOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym
# implementation

proc getSymRepr(s: PSym): string = 
  case s.kind
  of skProc, skMethod, skConverter, skIterator: result = getProcHeader(s)
  else: result = s.name.s
  
proc CloseScope(tab: var TSymTab) = 
  var 
    it: TTabIter
    s: PSym
  # check if all symbols have been used and defined:
  if (tab.tos > len(tab.stack)): InternalError("CloseScope")
  s = InitTabIter(it, tab.stack[tab.tos - 1])
  while s != nil: 
    if sfForward in s.flags: 
      liMessage(s.info, errImplOfXexpected, getSymRepr(s))
    elif ({sfUsed, sfInInterface} * s.flags == {}) and
        (optHints in s.options): # BUGFIX: check options in s!
      if not (s.kind in {skForVar, skParam, skMethod, skUnknown}): 
        liMessage(s.info, hintXDeclaredButNotUsed, getSymRepr(s))
    s = NextIter(it, tab.stack[tab.tos - 1])
  astalgo.rawCloseScope(tab)

proc AddSym(t: var TStrTable, n: PSym) = 
  if StrTableIncl(t, n): liMessage(n.info, errAttemptToRedefine, n.name.s)
  
proc addDecl(c: PContext, sym: PSym) = 
  if SymTabAddUnique(c.tab, sym) == Failure: 
    liMessage(sym.info, errAttemptToRedefine, sym.Name.s)
  
proc addDeclAt(c: PContext, sym: PSym, at: Natural) = 
  if SymTabAddUniqueAt(c.tab, sym, at) == Failure: 
    liMessage(sym.info, errAttemptToRedefine, sym.Name.s)
  
proc addOverloadableSymAt(c: PContext, fn: PSym, at: Natural) = 
  if not (fn.kind in OverloadableSyms): 
    InternalError(fn.info, "addOverloadableSymAt")
  var check = StrTableGet(c.tab.stack[at], fn.name)
  if (check != nil) and not (check.Kind in OverloadableSyms): 
    liMessage(fn.info, errAttemptToRedefine, fn.Name.s)
  SymTabAddAt(c.tab, fn, at)

proc AddInterfaceDeclAux(c: PContext, sym: PSym) = 
  if (sfInInterface in sym.flags): 
    # add to interface:
    if c.module == nil: InternalError(sym.info, "AddInterfaceDeclAux")
    StrTableAdd(c.module.tab, sym)
  if getCurrOwner().kind == skModule: incl(sym.flags, sfGlobal)
  
proc addInterfaceDecl(c: PContext, sym: PSym) = 
  # it adds the symbol to the interface if appropriate
  addDecl(c, sym)
  AddInterfaceDeclAux(c, sym)

proc addInterfaceOverloadableSymAt(c: PContext, sym: PSym, at: int) = 
  # it adds the symbol to the interface if appropriate
  addOverloadableSymAt(c, sym, at)
  AddInterfaceDeclAux(c, sym)

proc lookUp(c: PContext, n: PNode): PSym = 
  # Looks up a symbol. Generates an error in case of nil.
  case n.kind
  of nkAccQuoted: 
    result = lookup(c, n.sons[0])
  of nkSym: 
    #
    #      result := SymtabGet(c.Tab, n.sym.name);
    #      if result = nil then
    #        liMessage(n.info, errUndeclaredIdentifier, n.sym.name.s); 
    result = n.sym
  of nkIdent: 
    result = SymtabGet(c.Tab, n.ident)
    if result == nil: liMessage(n.info, errUndeclaredIdentifier, n.ident.s)
  else: InternalError(n.info, "lookUp")
  if IntSetContains(c.AmbiguousSymbols, result.id): 
    liMessage(n.info, errUseQualifier, result.name.s)
  if result.kind == skStub: loadStub(result)
  
proc QualifiedLookUp(c: PContext, n: PNode, ambiguousCheck: bool): PSym = 
  var 
    m: PSym
    ident: PIdent
  case n.kind
  of nkIdent: 
    result = SymtabGet(c.Tab, n.ident)
    if result == nil: 
      liMessage(n.info, errUndeclaredIdentifier, n.ident.s)
    elif ambiguousCheck and IntSetContains(c.AmbiguousSymbols, result.id): 
      liMessage(n.info, errUseQualifier, n.ident.s)
  of nkSym: 
    #
    #      result := SymtabGet(c.Tab, n.sym.name);
    #      if result = nil then
    #        liMessage(n.info, errUndeclaredIdentifier, n.sym.name.s)
    #      else 
    result = n.sym
    if ambiguousCheck and IntSetContains(c.AmbiguousSymbols, result.id): 
      liMessage(n.info, errUseQualifier, n.sym.name.s)
  of nkDotExpr: 
    result = nil
    m = qualifiedLookUp(c, n.sons[0], false)
    if (m != nil) and (m.kind == skModule): 
      ident = nil
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
        if result == nil: 
          liMessage(n.sons[1].info, errUndeclaredIdentifier, ident.s)
      else: 
        liMessage(n.sons[1].info, errIdentifierExpected, renderTree(n.sons[1]))
  of nkAccQuoted: 
    result = QualifiedLookup(c, n.sons[0], ambiguousCheck)
  else: 
    result = nil              #liMessage(n.info, errIdentifierExpected, '')
  if (result != nil) and (result.kind == skStub): loadStub(result)
  
proc InitOverloadIter(o: var TOverloadIter, c: PContext, n: PNode): PSym = 
  var ident: PIdent
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
    o.mode = oimDone #
                     #      o.stackPtr := c.tab.tos;
                     #      o.mode := oimNoQualifier;
                     #      while (result = nil) do begin
                     #        dec(o.stackPtr);
                     #        if o.stackPtr < 0 then break;
                     #        result := InitIdentIter(o.it, c.tab.stack[o.stackPtr], n.sym.name);
                     #      end; 
  of nkDotExpr: 
    o.mode = oimOtherModule
    o.m = qualifiedLookUp(c, n.sons[0], false)
    if (o.m != nil) and (o.m.kind == skModule): 
      ident = nil
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
        liMessage(n.sons[1].info, errIdentifierExpected, renderTree(n.sons[1]))
  of nkAccQuoted: 
    result = InitOverloadIter(o, c, n.sons[0])
  of nkSymChoice: 
    o.mode = oimSymChoice
    result = n.sons[0].sym
    o.stackPtr = 1
  else: 
    nil
  if (result != nil) and (result.kind == skStub): loadStub(result)
  
proc nextOverloadIter(o: var TOverloadIter, c: PContext, n: PNode): PSym = 
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
        result = InitIdentIter(o.it, c.tab.stack[o.stackPtr], o.it.name) # BUGFIX: 
                                                                         # o.it.name <-> n.ident
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
  