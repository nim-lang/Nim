#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements lookup helpers.

import
  intsets, ast, astalgo, idents, semdata, types, msgs, options, rodread,
  renderer, wordrecg, idgen

proc ensureNoMissingOrUnusedSymbols(scope: PScope)

proc considerAcc*(n: PNode): PIdent =
  case n.kind
  of nkIdent: result = n.ident
  of nkSym: result = n.sym.name
  of nkAccQuoted:
    case n.len
    of 0: GlobalError(n.info, errIdentifierExpected, renderTree(n))
    of 1: result = considerAcc(n.sons[0])
    else:
      var id = ""
      for i in 0.. <n.len:
        let x = n.sons[i]
        case x.kind
        of nkIdent: id.add(x.ident.s)
        of nkSym: id.add(x.sym.name.s)
        else: GlobalError(n.info, errIdentifierExpected, renderTree(n))
      result = getIdent(id)
  else:
    GlobalError(n.info, errIdentifierExpected, renderTree(n))

template addSym*(scope: PScope, s: PSym) =
  StrTableAdd(scope.symbols, s)

proc addUniqueSym*(scope: PScope, s: PSym): TResult =
  if StrTableIncl(scope.symbols, s):
    result = Failure
  else:
    result = Success

proc openScope*(c: PContext): PScope {.discardable.} =
  result = PScope(parent: c.currentScope,
                  symbols: newStrTable(),
                  depthLevel: c.scopeDepth + 1)
  c.currentScope = result

proc rawCloseScope*(c: PContext) =
  c.currentScope = c.currentScope.parent

proc closeScope*(c: PContext) =
  ensureNoMissingOrUnusedSymbols(c.currentScope)
  rawCloseScope(c)

iterator walkScopes*(scope: PScope): PScope =
  var current = scope
  while current != nil:
    yield current
    current = current.parent

proc localSearchInScope*(c: PContext, s: PIdent): PSym =
  result = StrTableGet(c.currentScope.symbols, s)

proc searchInScopes*(c: PContext, s: PIdent): PSym =
  for scope in walkScopes(c.currentScope):
    result = StrTableGet(scope.symbols, s)
    if result != nil: return
  result = nil

proc searchInScopes*(c: PContext, s: PIdent, filter: TSymKinds): PSym =
  for scope in walkScopes(c.currentScope):
    result = StrTableGet(scope.symbols, s)
    if result != nil and result.kind in filter: return
  result = nil

proc errorSym*(c: PContext, n: PNode): PSym =
  ## creates an error symbol to avoid cascading errors (for IDE support)
  var m = n
  # ensure that 'considerAcc' can't fail:
  if m.kind == nkDotExpr: m = m.sons[1]
  let ident = if m.kind in {nkIdent, nkSym, nkAccQuoted}:
      considerAcc(m)
    else:
      getIdent("err:" & renderTree(m))
  result = newSym(skError, ident, getCurrOwner(), n.info)
  result.typ = errorType(c)
  incl(result.flags, sfDiscardable)
  # pretend it's imported from some unknown module to prevent cascading errors:
  if gCmd != cmdInteractive:
    c.importTable.addSym(result)

type
  TOverloadIterMode* = enum
    oimDone, oimNoQualifier, oimSelfModule, oimOtherModule, oimSymChoice,
    oimSymChoiceLocalLookup
  TOverloadIter*{.final.} = object
    it*: TIdentIter
    m*: PSym
    mode*: TOverloadIterMode
    symChoiceIndex*: int
    scope*: PScope
    inSymChoice: TIntSet

proc getSymRepr*(s: PSym): string =
  case s.kind
  of skProc, skMethod, skConverter, skIterator: result = getProcHeader(s)
  else: result = s.name.s

proc ensureNoMissingOrUnusedSymbols(scope: PScope) =
  # check if all symbols have been used and defined:
  var it: TTabIter
  var s = InitTabIter(it, scope.symbols)
  var missingImpls = 0
  while s != nil:
    if sfForward in s.flags:
      # too many 'implementation of X' errors are annoying
      # and slow 'suggest' down:
      if missingImpls == 0:
        LocalError(s.info, errImplOfXexpected, getSymRepr(s))
      inc missingImpls
    elif {sfUsed, sfExported} * s.flags == {} and optHints in s.options:
      # BUGFIX: check options in s!
      if s.kind notin {skForVar, skParam, skMethod, skUnknown, skGenericParam}:
        Message(s.info, hintXDeclaredButNotUsed, getSymRepr(s))
    s = NextIter(it, scope.symbols)

proc WrongRedefinition*(info: TLineInfo, s: string) =
  if gCmd != cmdInteractive:
    localError(info, errAttemptToRedefine, s)

proc addDecl*(c: PContext, sym: PSym) =
  if c.currentScope.addUniqueSym(sym) == Failure:
    WrongRedefinition(sym.info, sym.Name.s)

proc addPrelimDecl*(c: PContext, sym: PSym) =
  discard c.currentScope.addUniqueSym(sym)

proc addDeclAt*(scope: PScope, sym: PSym) =
  if scope.addUniqueSym(sym) == Failure:
    WrongRedefinition(sym.info, sym.Name.s)

proc AddInterfaceDeclAux(c: PContext, sym: PSym) =
  if sfExported in sym.flags:
    # add to interface:
    if c.module != nil: StrTableAdd(c.module.tab, sym)
    else: InternalError(sym.info, "AddInterfaceDeclAux")

proc addInterfaceDeclAt*(c: PContext, scope: PScope, sym: PSym) =
  addDeclAt(scope, sym)
  AddInterfaceDeclAux(c, sym)

proc addOverloadableSymAt*(scope: PScope, fn: PSym) =
  if fn.kind notin OverloadableSyms:
    InternalError(fn.info, "addOverloadableSymAt")
    return
  var check = StrTableGet(scope.symbols, fn.name)
  if check != nil and check.Kind notin OverloadableSyms:
    WrongRedefinition(fn.info, fn.Name.s)
  else:
    scope.addSym(fn)

proc addInterfaceDecl*(c: PContext, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addDecl(c, sym)
  AddInterfaceDeclAux(c, sym)

proc addInterfaceOverloadableSymAt*(c: PContext, scope: PScope, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addOverloadableSymAt(scope, sym)
  AddInterfaceDeclAux(c, sym)

proc lookUp*(c: PContext, n: PNode): PSym =
  # Looks up a symbol. Generates an error in case of nil.
  case n.kind
  of nkIdent:
    result = searchInScopes(c, n.ident)
    if result == nil:
      LocalError(n.info, errUndeclaredIdentifier, n.ident.s)
      result = errorSym(c, n)
  of nkSym:
    result = n.sym
  of nkAccQuoted:
    var ident = considerAcc(n)
    result = searchInScopes(c, ident)
    if result == nil:
      LocalError(n.info, errUndeclaredIdentifier, ident.s)
      result = errorSym(c, n)
  else:
    InternalError(n.info, "lookUp")
    return
  if Contains(c.AmbiguousSymbols, result.id):
    LocalError(n.info, errUseQualifier, result.name.s)
  if result.kind == skStub: loadStub(result)

type
  TLookupFlag* = enum
    checkAmbiguity, checkUndeclared

proc QualifiedLookUp*(c: PContext, n: PNode, flags = {checkUndeclared}): PSym =
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerAcc(n)
    result = searchInScopes(c, ident)
    if result == nil and checkUndeclared in flags:
      LocalError(n.info, errUndeclaredIdentifier, ident.s)
      result = errorSym(c, n)
    elif checkAmbiguity in flags and result != nil and
        Contains(c.AmbiguousSymbols, result.id):
      LocalError(n.info, errUseQualifier, ident.s)
  of nkSym:
    result = n.sym
    if checkAmbiguity in flags and Contains(c.AmbiguousSymbols, result.id):
      LocalError(n.info, errUseQualifier, n.sym.name.s)
  of nkDotExpr:
    result = nil
    var m = qualifiedLookUp(c, n.sons[0], flags*{checkUndeclared})
    if (m != nil) and (m.kind == skModule):
      var ident: PIdent = nil
      if n.sons[1].kind == nkIdent:
        ident = n.sons[1].ident
      elif n.sons[1].kind == nkAccQuoted:
        ident = considerAcc(n.sons[1])
      if ident != nil:
        if m == c.module:
          result = StrTableGet(c.topLevelScope.symbols, ident)
        else:
          result = StrTableGet(m.tab, ident)
        if result == nil and checkUndeclared in flags:
          LocalError(n.sons[1].info, errUndeclaredIdentifier, ident.s)
          result = errorSym(c, n.sons[1])
      elif checkUndeclared in flags:
        LocalError(n.sons[1].info, errIdentifierExpected,
                   renderTree(n.sons[1]))
        result = errorSym(c, n.sons[1])
  else:
    result = nil
  if result != nil and result.kind == skStub: loadStub(result)

proc InitOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerAcc(n)
    o.scope = c.currentScope
    o.mode = oimNoQualifier
    while true:
      result = InitIdentIter(o.it, o.scope.symbols, ident)
      if result != nil:
        break
      else:
        o.scope = o.scope.parent
        if o.scope == nil: break
  of nkSym:
    result = n.sym
    o.mode = oimDone
  of nkDotExpr:
    o.mode = oimOtherModule
    o.m = qualifiedLookUp(c, n.sons[0])
    if o.m != nil and o.m.kind == skModule:
      var ident: PIdent = nil
      if n.sons[1].kind == nkIdent:
        ident = n.sons[1].ident
      elif n.sons[1].kind == nkAccQuoted:
        ident = considerAcc(n.sons[1])
      if ident != nil:
        if o.m == c.module:
          # a module may access its private members:
          result = InitIdentIter(o.it, c.topLevelScope.symbols, ident)
          o.mode = oimSelfModule
        else:
          result = InitIdentIter(o.it, o.m.tab, ident)
      else:
        LocalError(n.sons[1].info, errIdentifierExpected,
                   renderTree(n.sons[1]))
        result = errorSym(c, n.sons[1])
  of nkClosedSymChoice, nkOpenSymChoice:
    o.mode = oimSymChoice
    result = n.sons[0].sym
    o.symChoiceIndex = 1
    o.inSymChoice = initIntSet()
    Incl(o.inSymChoice, result.id)
  else: nil
  if result != nil and result.kind == skStub: loadStub(result)

proc lastOverloadScope*(o: TOverloadIter): int =
  case o.mode
  of oimNoQualifier: result = if o.scope.isNil: -1 else: o.scope.depthLevel
  of oimSelfModule:  result = 1
  of oimOtherModule: result = 0
  else: result = -1

proc nextOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  case o.mode
  of oimDone:
    result = nil
  of oimNoQualifier:
    if o.scope != nil:
      result = nextIdentIter(o.it, o.scope.symbols)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = InitIdentIter(o.it, o.scope.symbols, o.it.name)
        # BUGFIX: o.it.name <-> n.ident
    else:
      result = nil
  of oimSelfModule:
    result = nextIdentIter(o.it, c.topLevelScope.symbols)
  of oimOtherModule:
    result = nextIdentIter(o.it, o.m.tab)
  of oimSymChoice:
    if o.symChoiceIndex < sonsLen(n):
      result = n.sons[o.symChoiceIndex].sym
      Incl(o.inSymChoice, result.id)
      inc o.symChoiceIndex
    elif n.kind == nkOpenSymChoice:
      # try 'local' symbols too for Koenig's lookup:
      o.mode = oimSymChoiceLocalLookup
      o.scope = c.currentScope
      result = FirstIdentExcluding(o.it, o.scope.symbols,
                                   n.sons[0].sym.name, o.inSymChoice)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = FirstIdentExcluding(o.it, o.scope.symbols,
                                     n.sons[0].sym.name, o.inSymChoice)
  of oimSymChoiceLocalLookup:
    result = nextIdentExcluding(o.it, o.scope.symbols, o.inSymChoice)
    while result == nil:
      o.scope = o.scope.parent
      if o.scope == nil: break
      result = FirstIdentExcluding(o.it, o.scope.symbols,
                                   n.sons[0].sym.name, o.inSymChoice)

  if result != nil and result.kind == skStub: loadStub(result)

