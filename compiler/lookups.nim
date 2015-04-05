#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements lookup helpers.

import
  intsets, ast, astalgo, idents, semdata, types, msgs, options, rodread,
  renderer, wordrecg, idgen, nimfix.prettybase

proc ensureNoMissingOrUnusedSymbols(scope: PScope)

proc considerQuotedIdent*(n: PNode): PIdent =
  ## Retrieve a PIdent from a PNode, taking into account accent nodes.
  case n.kind
  of nkIdent: result = n.ident
  of nkSym: result = n.sym.name
  of nkAccQuoted:
    case n.len
    of 0:
      localError(n.info, errIdentifierExpected, renderTree(n))
      result = getIdent"<Error>"
    of 1: result = considerQuotedIdent(n.sons[0])
    else:
      var id = ""
      for i in 0.. <n.len:
        let x = n.sons[i]
        case x.kind
        of nkIdent: id.add(x.ident.s)
        of nkSym: id.add(x.sym.name.s)
        else:
          localError(n.info, errIdentifierExpected, renderTree(n))
          return getIdent"<Error>"
      result = getIdent(id)
  of nkOpenSymChoice, nkClosedSymChoice: result = n.sons[0].sym.name
  else:
    localError(n.info, errIdentifierExpected, renderTree(n))
    result = getIdent"<Error>"

template addSym*(scope: PScope, s: PSym) =
  strTableAdd(scope.symbols, s)

proc addUniqueSym*(scope: PScope, s: PSym): bool =
  result = not strTableIncl(scope.symbols, s)

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

proc skipAlias*(s: PSym; n: PNode): PSym =
  if s == nil or s.kind != skAlias:
    result = s
  else:
    result = s.owner
    if gCmd == cmdPretty:
      prettybase.replaceDeprecated(n.info, s, result)
    else:
      message(n.info, warnDeprecated, "use " & result.name.s & " instead; " &
              s.name.s)

proc localSearchInScope*(c: PContext, s: PIdent): PSym =
  result = strTableGet(c.currentScope.symbols, s)

proc searchInScopes*(c: PContext, s: PIdent): PSym =
  for scope in walkScopes(c.currentScope):
    result = strTableGet(scope.symbols, s)
    if result != nil: return
  result = nil

proc debugScopes*(c: PContext; limit=0) {.deprecated.} =
  var i = 0
  for scope in walkScopes(c.currentScope):
    echo "scope ", i
    for h in 0 .. high(scope.symbols.data):
      if scope.symbols.data[h] != nil:
        echo scope.symbols.data[h].name.s
    if i == limit: break
    inc i

proc searchInScopes*(c: PContext, s: PIdent, filter: TSymKinds): PSym =
  for scope in walkScopes(c.currentScope):
    result = strTableGet(scope.symbols, s)
    if result != nil and result.kind in filter: return
  result = nil

proc errorSym*(c: PContext, n: PNode): PSym =
  ## creates an error symbol to avoid cascading errors (for IDE support)
  var m = n
  # ensure that 'considerQuotedIdent' can't fail:
  if m.kind == nkDotExpr: m = m.sons[1]
  let ident = if m.kind in {nkIdent, nkSym, nkAccQuoted}:
      considerQuotedIdent(m)
    else:
      getIdent("err:" & renderTree(m))
  result = newSym(skError, ident, getCurrOwner(), n.info)
  result.typ = errorType(c)
  incl(result.flags, sfDiscardable)
  # pretend it's imported from some unknown module to prevent cascading errors:
  if gCmd != cmdInteractive and c.inCompilesContext == 0:
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
    inSymChoice: IntSet

proc getSymRepr*(s: PSym): string =
  case s.kind
  of skProc, skMethod, skConverter, skIterators: result = getProcHeader(s)
  else: result = s.name.s

proc ensureNoMissingOrUnusedSymbols(scope: PScope) =
  # check if all symbols have been used and defined:
  var it: TTabIter
  var s = initTabIter(it, scope.symbols)
  var missingImpls = 0
  while s != nil:
    if sfForward in s.flags:
      # too many 'implementation of X' errors are annoying
      # and slow 'suggest' down:
      if missingImpls == 0:
        localError(s.info, errImplOfXexpected, getSymRepr(s))
      inc missingImpls
    elif {sfUsed, sfExported} * s.flags == {} and optHints in s.options:
      # BUGFIX: check options in s!
      if s.kind notin {skForVar, skParam, skMethod, skUnknown, skGenericParam}:
        # XXX: implicit type params are currently skTypes
        # maybe they can be made skGenericParam as well.
        if s.typ != nil and tfImplicitTypeParam notin s.typ.flags:
          message(s.info, hintXDeclaredButNotUsed, getSymRepr(s))
    s = nextIter(it, scope.symbols)

proc wrongRedefinition*(info: TLineInfo, s: string) =
  if gCmd != cmdInteractive:
    localError(info, errAttemptToRedefine, s)

proc addDecl*(c: PContext, sym: PSym) =
  if not c.currentScope.addUniqueSym(sym):
    wrongRedefinition(sym.info, sym.name.s)

proc addPrelimDecl*(c: PContext, sym: PSym) =
  discard c.currentScope.addUniqueSym(sym)

proc addDeclAt*(scope: PScope, sym: PSym) =
  if not scope.addUniqueSym(sym):
    wrongRedefinition(sym.info, sym.name.s)

proc addInterfaceDeclAux(c: PContext, sym: PSym) =
  if sfExported in sym.flags:
    # add to interface:
    if c.module != nil: strTableAdd(c.module.tab, sym)
    else: internalError(sym.info, "addInterfaceDeclAux")

proc addInterfaceDeclAt*(c: PContext, scope: PScope, sym: PSym) =
  addDeclAt(scope, sym)
  addInterfaceDeclAux(c, sym)

proc addOverloadableSymAt*(scope: PScope, fn: PSym) =
  if fn.kind notin OverloadableSyms:
    internalError(fn.info, "addOverloadableSymAt")
    return
  let check = strTableGet(scope.symbols, fn.name)
  if check != nil and check.kind notin OverloadableSyms:
    wrongRedefinition(fn.info, fn.name.s)
  else:
    scope.addSym(fn)

proc addInterfaceDecl*(c: PContext, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addDecl(c, sym)
  addInterfaceDeclAux(c, sym)

proc addInterfaceOverloadableSymAt*(c: PContext, scope: PScope, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addOverloadableSymAt(scope, sym)
  addInterfaceDeclAux(c, sym)

when defined(nimfix):
  import strutils

  # when we cannot find the identifier, retry with a changed identifer:
  proc altSpelling(x: PIdent): PIdent =
    case x.s[0]
    of 'A'..'Z': result = getIdent(toLower(x.s[0]) & x.s.substr(1))
    of 'a'..'z': result = getIdent(toLower(x.s[0]) & x.s.substr(1))
    else: result = x

  template fixSpelling(n: PNode; ident: PIdent; op: expr) =
    let alt = ident.altSpelling
    result = op(c, alt).skipAlias(n)
    if result != nil:
      prettybase.replaceDeprecated(n.info, ident, alt)
      return result
else:
  template fixSpelling(n: PNode; ident: PIdent; op: expr) = discard

proc lookUp*(c: PContext, n: PNode): PSym =
  # Looks up a symbol. Generates an error in case of nil.
  case n.kind
  of nkIdent:
    result = searchInScopes(c, n.ident).skipAlias(n)
    if result == nil:
      fixSpelling(n, n.ident, searchInScopes)
      localError(n.info, errUndeclaredIdentifier, n.ident.s)
      result = errorSym(c, n)
  of nkSym:
    result = n.sym
  of nkAccQuoted:
    var ident = considerQuotedIdent(n)
    result = searchInScopes(c, ident).skipAlias(n)
    if result == nil:
      fixSpelling(n, ident, searchInScopes)
      localError(n.info, errUndeclaredIdentifier, ident.s)
      result = errorSym(c, n)
  else:
    internalError(n.info, "lookUp")
    return
  if contains(c.ambiguousSymbols, result.id):
    localError(n.info, errUseQualifier, result.name.s)
  if result.kind == skStub: loadStub(result)

type
  TLookupFlag* = enum
    checkAmbiguity, checkUndeclared

proc qualifiedLookUp*(c: PContext, n: PNode, flags = {checkUndeclared}): PSym =
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerQuotedIdent(n)
    result = searchInScopes(c, ident).skipAlias(n)
    if result == nil and checkUndeclared in flags:
      fixSpelling(n, ident, searchInScopes)
      localError(n.info, errUndeclaredIdentifier, ident.s)
      result = errorSym(c, n)
    elif checkAmbiguity in flags and result != nil and
        contains(c.ambiguousSymbols, result.id):
      localError(n.info, errUseQualifier, ident.s)
  of nkSym:
    result = n.sym
    if checkAmbiguity in flags and contains(c.ambiguousSymbols, result.id):
      localError(n.info, errUseQualifier, n.sym.name.s)
  of nkDotExpr:
    result = nil
    var m = qualifiedLookUp(c, n.sons[0], flags*{checkUndeclared})
    if m != nil and m.kind == skModule:
      var ident: PIdent = nil
      if n.sons[1].kind == nkIdent:
        ident = n.sons[1].ident
      elif n.sons[1].kind == nkAccQuoted:
        ident = considerQuotedIdent(n.sons[1])
      if ident != nil:
        if m == c.module:
          result = strTableGet(c.topLevelScope.symbols, ident).skipAlias(n)
        else:
          result = strTableGet(m.tab, ident).skipAlias(n)
        if result == nil and checkUndeclared in flags:
          fixSpelling(n.sons[1], ident, searchInScopes)
          localError(n.sons[1].info, errUndeclaredIdentifier, ident.s)
          result = errorSym(c, n.sons[1])
      elif n.sons[1].kind == nkSym:
        result = n.sons[1].sym
      elif checkUndeclared in flags and
           n.sons[1].kind notin {nkOpenSymChoice, nkClosedSymChoice}:
        localError(n.sons[1].info, errIdentifierExpected,
                   renderTree(n.sons[1]))
        result = errorSym(c, n.sons[1])
  else:
    result = nil
  if result != nil and result.kind == skStub: loadStub(result)

proc initOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerQuotedIdent(n)
    o.scope = c.currentScope
    o.mode = oimNoQualifier
    while true:
      result = initIdentIter(o.it, o.scope.symbols, ident).skipAlias(n)
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
        ident = considerQuotedIdent(n.sons[1])
      if ident != nil:
        if o.m == c.module:
          # a module may access its private members:
          result = initIdentIter(o.it, c.topLevelScope.symbols,
                                 ident).skipAlias(n)
          o.mode = oimSelfModule
        else:
          result = initIdentIter(o.it, o.m.tab, ident).skipAlias(n)
      else:
        localError(n.sons[1].info, errIdentifierExpected,
                   renderTree(n.sons[1]))
        result = errorSym(c, n.sons[1])
  of nkClosedSymChoice, nkOpenSymChoice:
    o.mode = oimSymChoice
    result = n.sons[0].sym
    o.symChoiceIndex = 1
    o.inSymChoice = initIntSet()
    incl(o.inSymChoice, result.id)
  else: discard
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
      result = nextIdentIter(o.it, o.scope.symbols).skipAlias(n)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = initIdentIter(o.it, o.scope.symbols, o.it.name).skipAlias(n)
        # BUGFIX: o.it.name <-> n.ident
    else:
      result = nil
  of oimSelfModule:
    result = nextIdentIter(o.it, c.topLevelScope.symbols).skipAlias(n)
  of oimOtherModule:
    result = nextIdentIter(o.it, o.m.tab).skipAlias(n)
  of oimSymChoice:
    if o.symChoiceIndex < sonsLen(n):
      result = n.sons[o.symChoiceIndex].sym
      incl(o.inSymChoice, result.id)
      inc o.symChoiceIndex
    elif n.kind == nkOpenSymChoice:
      # try 'local' symbols too for Koenig's lookup:
      o.mode = oimSymChoiceLocalLookup
      o.scope = c.currentScope
      result = firstIdentExcluding(o.it, o.scope.symbols,
                                   n.sons[0].sym.name, o.inSymChoice).skipAlias(n)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = firstIdentExcluding(o.it, o.scope.symbols,
                                     n.sons[0].sym.name, o.inSymChoice).skipAlias(n)
  of oimSymChoiceLocalLookup:
    result = nextIdentExcluding(o.it, o.scope.symbols, o.inSymChoice).skipAlias(n)
    while result == nil:
      o.scope = o.scope.parent
      if o.scope == nil: break
      result = firstIdentExcluding(o.it, o.scope.symbols,
                                   n.sons[0].sym.name, o.inSymChoice).skipAlias(n)

  if result != nil and result.kind == skStub: loadStub(result)

proc pickSym*(c: PContext, n: PNode; kind: TSymKind;
              flags: TSymFlags = {}): PSym =
  var o: TOverloadIter
  var a = initOverloadIter(o, c, n)
  while a != nil:
    if a.kind == kind and flags <= a.flags:
      return a
    a = nextOverloadIter(o, c, n)
