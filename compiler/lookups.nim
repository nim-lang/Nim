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
  intsets, ast, astalgo, idents, semdata, types, msgs, options,
  renderer, wordrecg, idgen, nimfix/prettybase, lineinfos, strutils

proc ensureNoMissingOrUnusedSymbols(c: PContext; scope: PScope)

proc noidentError(conf: ConfigRef; n, origin: PNode) =
  var m = ""
  if origin != nil:
    m.add "in expression '" & origin.renderTree & "': "
  m.add "identifier expected, but found '" & n.renderTree & "'"
  localError(conf, n.info, m)

proc considerQuotedIdent*(c: PContext; n: PNode, origin: PNode = nil): PIdent =
  ## Retrieve a PIdent from a PNode, taking into account accent nodes.
  ## ``origin`` can be nil. If it is not nil, it is used for a better
  ## error message.
  template handleError(n, origin: PNode) =
    noidentError(c.config, n, origin)
    result = getIdent(c.cache, "<Error>")

  case n.kind
  of nkIdent: result = n.ident
  of nkSym: result = n.sym.name
  of nkAccQuoted:
    case n.len
    of 0: handleError(n, origin)
    of 1: result = considerQuotedIdent(c, n.sons[0], origin)
    else:
      var id = ""
      for i in 0..<n.len:
        let x = n.sons[i]
        case x.kind
        of nkIdent: id.add(x.ident.s)
        of nkSym: id.add(x.sym.name.s)
        of nkLiterals - nkFloatLiterals: id.add(x.renderTree)
        else: handleError(n, origin)
      result = getIdent(c.cache, id)
  of nkOpenSymChoice, nkClosedSymChoice:
    if n[0].kind == nkSym:
      result = n.sons[0].sym.name
    else:
      handleError(n, origin)
  else:
    handleError(n, origin)

template addSym*(scope: PScope, s: PSym) =
  strTableAdd(scope.symbols, s)

proc addUniqueSym*(scope: PScope, s: PSym): PSym =
  result = strTableInclReportConflict(scope.symbols, s)

proc openScope*(c: PContext): PScope {.discardable.} =
  result = PScope(parent: c.currentScope,
                  symbols: newStrTable(),
                  depthLevel: c.scopeDepth + 1)
  c.currentScope = result

proc rawCloseScope*(c: PContext) =
  c.currentScope = c.currentScope.parent

proc closeScope*(c: PContext) =
  ensureNoMissingOrUnusedSymbols(c, c.currentScope)
  rawCloseScope(c)

iterator walkScopes*(scope: PScope): PScope =
  var current = scope
  while current != nil:
    yield current
    current = current.parent

proc skipAlias*(s: PSym; n: PNode; conf: ConfigRef): PSym =
  if s == nil or s.kind != skAlias:
    result = s
  else:
    result = s.owner
    if conf.cmd == cmdPretty:
      prettybase.replaceDeprecated(conf, n.info, s, result)
    else:
      message(conf, n.info, warnDeprecated, "use " & result.name.s & " instead; " &
              s.name.s & " is deprecated")

proc localSearchInScope*(c: PContext, s: PIdent): PSym =
  result = strTableGet(c.currentScope.symbols, s)

proc searchInScopes*(c: PContext, s: PIdent): PSym =
  for scope in walkScopes(c.currentScope):
    result = strTableGet(scope.symbols, s)
    if result != nil: return
  result = nil

when declared(echo):
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
    var ti: TIdentIter
    var candidate = initIdentIter(ti, scope.symbols, s)
    while candidate != nil:
      if candidate.kind in filter: return candidate
      candidate = nextIdentIter(ti, scope.symbols)
  result = nil

proc errorSym*(c: PContext, n: PNode): PSym =
  ## creates an error symbol to avoid cascading errors (for IDE support)
  var m = n
  # ensure that 'considerQuotedIdent' can't fail:
  if m.kind == nkDotExpr: m = m.sons[1]
  let ident = if m.kind in {nkIdent, nkSym, nkAccQuoted}:
      considerQuotedIdent(c, m)
    else:
      getIdent(c.cache, "err:" & renderTree(m))
  result = newSym(skError, ident, getCurrOwner(c), n.info, {})
  result.typ = errorType(c)
  incl(result.flags, sfDiscardable)
  # pretend it's imported from some unknown module to prevent cascading errors:
  if c.config.cmd != cmdInteractive and c.compilesContextId == 0:
    c.importTable.addSym(result)

type
  TOverloadIterMode* = enum
    oimDone, oimNoQualifier, oimSelfModule, oimOtherModule, oimSymChoice,
    oimSymChoiceLocalLookup
  TOverloadIter* = object
    it*: TIdentIter
    m*: PSym
    mode*: TOverloadIterMode
    symChoiceIndex*: int
    scope*: PScope
    inSymChoice: IntSet

proc getSymRepr*(conf: ConfigRef; s: PSym): string =
  case s.kind
  of routineKinds, skType:
    result = getProcHeader(conf, s)
  else:
    result = s.name.s

proc ensureNoMissingOrUnusedSymbols(c: PContext; scope: PScope) =
  # check if all symbols have been used and defined:
  var it: TTabIter
  var s = initTabIter(it, scope.symbols)
  var missingImpls = 0
  while s != nil:
    if sfForward in s.flags and s.kind notin {skType, skModule}:
      # too many 'implementation of X' errors are annoying
      # and slow 'suggest' down:
      if missingImpls == 0:
        localError(c.config, s.info, "implementation of '$1' expected" %
            getSymRepr(c.config, s))
      inc missingImpls
    elif {sfUsed, sfExported} * s.flags == {}:
      if s.kind notin {skForVar, skParam, skMethod, skUnknown, skGenericParam, skEnumField}:
        # XXX: implicit type params are currently skTypes
        # maybe they can be made skGenericParam as well.
        if s.typ != nil and tfImplicitTypeParam notin s.typ.flags and
           s.typ.kind != tyGenericParam:
          message(c.config, s.info, hintXDeclaredButNotUsed, s.name.s)
    s = nextIter(it, scope.symbols)

proc wrongRedefinition*(c: PContext; info: TLineInfo, s: string;
                        conflictsWith: TLineInfo) =
  if c.config.cmd != cmdInteractive:
    localError(c.config, info,
      "redefinition of '$1'; previous declaration here: $2" %
      [s, c.config $ conflictsWith])

proc addDecl*(c: PContext, sym: PSym, info: TLineInfo) =
  let conflict = c.currentScope.addUniqueSym(sym)
  if conflict != nil:
    wrongRedefinition(c, info, sym.name.s, conflict.info)

proc addDecl*(c: PContext, sym: PSym) =
  let conflict = strTableInclReportConflict(c.currentScope.symbols, sym, true)
  if conflict != nil:
    wrongRedefinition(c, sym.info, sym.name.s, conflict.info)

proc addPrelimDecl*(c: PContext, sym: PSym) =
  discard c.currentScope.addUniqueSym(sym)

proc addDeclAt*(c: PContext; scope: PScope, sym: PSym) =
  let conflict = scope.addUniqueSym(sym)
  if conflict != nil:
    wrongRedefinition(c, sym.info, sym.name.s, conflict.info)

proc addInterfaceDeclAux(c: PContext, sym: PSym) =
  if sfExported in sym.flags:
    # add to interface:
    if c.module != nil: strTableAdd(c.module.tab, sym)
    else: internalError(c.config, sym.info, "addInterfaceDeclAux")

proc addInterfaceDeclAt*(c: PContext, scope: PScope, sym: PSym) =
  addDeclAt(c, scope, sym)
  addInterfaceDeclAux(c, sym)

proc addOverloadableSymAt*(c: PContext; scope: PScope, fn: PSym) =
  if fn.kind notin OverloadableSyms:
    internalError(c.config, fn.info, "addOverloadableSymAt")
    return
  let check = strTableGet(scope.symbols, fn.name)
  if check != nil and check.kind notin OverloadableSyms:
    wrongRedefinition(c, fn.info, fn.name.s, check.info)
  else:
    scope.addSym(fn)

proc addInterfaceDecl*(c: PContext, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addDecl(c, sym)
  addInterfaceDeclAux(c, sym)

proc addInterfaceOverloadableSymAt*(c: PContext, scope: PScope, sym: PSym) =
  # it adds the symbol to the interface if appropriate
  addOverloadableSymAt(c, scope, sym)
  addInterfaceDeclAux(c, sym)

when defined(nimfix):
  # when we cannot find the identifier, retry with a changed identifer:
  proc altSpelling(x: PIdent): PIdent =
    case x.s[0]
    of 'A'..'Z': result = getIdent(toLowerAscii(x.s[0]) & x.s.substr(1))
    of 'a'..'z': result = getIdent(toLowerAscii(x.s[0]) & x.s.substr(1))
    else: result = x

  template fixSpelling(n: PNode; ident: PIdent; op: untyped) =
    let alt = ident.altSpelling
    result = op(c, alt).skipAlias(n)
    if result != nil:
      prettybase.replaceDeprecated(n.info, ident, alt)
      return result
else:
  template fixSpelling(n: PNode; ident: PIdent; op: untyped) = discard

proc errorUseQualifier*(c: PContext; info: TLineInfo; s: PSym) =
  var err = "ambiguous identifier: '" & s.name.s & "'"
  var ti: TIdentIter
  var candidate = initIdentIter(ti, c.importTable.symbols, s.name)
  var i = 0
  while candidate != nil:
    if i == 0: err.add " -- use one of the following:\n"
    else: err.add "\n"
    err.add "  " & candidate.owner.name.s & "." & candidate.name.s
    err.add ": " & typeToString(candidate.typ)
    candidate = nextIdentIter(ti, c.importTable.symbols)
    inc i
  localError(c.config, info, errGenerated, err)

proc errorUndeclaredIdentifier*(c: PContext; info: TLineInfo; name: string) =
  var err = "undeclared identifier: '" & name & "'"
  if c.recursiveDep.len > 0:
    err.add "\nThis might be caused by a recursive module dependency:\n"
    err.add c.recursiveDep
    # prevent excessive errors for 'nim check'
    c.recursiveDep = ""
  localError(c.config, info, errGenerated, err)

proc lookUp*(c: PContext, n: PNode): PSym =
  # Looks up a symbol. Generates an error in case of nil.
  case n.kind
  of nkIdent:
    result = searchInScopes(c, n.ident).skipAlias(n, c.config)
    if result == nil:
      fixSpelling(n, n.ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, n.ident.s)
      result = errorSym(c, n)
  of nkSym:
    result = n.sym
  of nkAccQuoted:
    var ident = considerQuotedIdent(c, n)
    result = searchInScopes(c, ident).skipAlias(n, c.config)
    if result == nil:
      fixSpelling(n, ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, ident.s)
      result = errorSym(c, n)
  else:
    internalError(c.config, n.info, "lookUp")
    return
  if contains(c.ambiguousSymbols, result.id):
    errorUseQualifier(c, n.info, result)
  when false:
    if result.kind == skStub: loadStub(result)

type
  TLookupFlag* = enum
    checkAmbiguity, checkUndeclared, checkModule, checkPureEnumFields

proc qualifiedLookUp*(c: PContext, n: PNode, flags: set[TLookupFlag]): PSym =
  const allExceptModule = {low(TSymKind)..high(TSymKind)}-{skModule,skPackage}
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerQuotedIdent(c, n)
    if checkModule in flags:
      result = searchInScopes(c, ident).skipAlias(n, c.config)
    else:
      result = searchInScopes(c, ident, allExceptModule).skipAlias(n, c.config)
    if result == nil and checkPureEnumFields in flags:
      result = strTableGet(c.pureEnumFields, ident)
    if result == nil and checkUndeclared in flags:
      fixSpelling(n, ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, ident.s)
      result = errorSym(c, n)
    elif checkAmbiguity in flags and result != nil and
        contains(c.ambiguousSymbols, result.id):
      errorUseQualifier(c, n.info, result)
  of nkSym:
    result = n.sym
    if checkAmbiguity in flags and contains(c.ambiguousSymbols, result.id):
      errorUseQualifier(c, n.info, n.sym)
  of nkDotExpr:
    result = nil
    var m = qualifiedLookUp(c, n.sons[0], (flags*{checkUndeclared})+{checkModule})
    if m != nil and m.kind == skModule:
      var ident: PIdent = nil
      if n.sons[1].kind == nkIdent:
        ident = n.sons[1].ident
      elif n.sons[1].kind == nkAccQuoted:
        ident = considerQuotedIdent(c, n.sons[1])
      if ident != nil:
        if m == c.module:
          result = strTableGet(c.topLevelScope.symbols, ident).skipAlias(n, c.config)
        else:
          result = strTableGet(m.tab, ident).skipAlias(n, c.config)
        if result == nil and checkUndeclared in flags:
          fixSpelling(n.sons[1], ident, searchInScopes)
          errorUndeclaredIdentifier(c, n.sons[1].info, ident.s)
          result = errorSym(c, n.sons[1])
      elif n.sons[1].kind == nkSym:
        result = n.sons[1].sym
      elif checkUndeclared in flags and
           n.sons[1].kind notin {nkOpenSymChoice, nkClosedSymChoice}:
        localError(c.config, n.sons[1].info, "identifier expected, but got: " &
                   renderTree(n.sons[1]))
        result = errorSym(c, n.sons[1])
  else:
    result = nil
  when false:
    if result != nil and result.kind == skStub: loadStub(result)

proc initOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerQuotedIdent(c, n)
    o.scope = c.currentScope
    o.mode = oimNoQualifier
    while true:
      result = initIdentIter(o.it, o.scope.symbols, ident).skipAlias(n, c.config)
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
    o.m = qualifiedLookUp(c, n.sons[0], {checkUndeclared, checkModule})
    if o.m != nil and o.m.kind == skModule:
      var ident: PIdent = nil
      if n.sons[1].kind == nkIdent:
        ident = n.sons[1].ident
      elif n.sons[1].kind == nkAccQuoted:
        ident = considerQuotedIdent(c, n.sons[1], n)
      if ident != nil:
        if o.m == c.module:
          # a module may access its private members:
          result = initIdentIter(o.it, c.topLevelScope.symbols,
                                 ident).skipAlias(n, c.config)
          o.mode = oimSelfModule
        else:
          result = initIdentIter(o.it, o.m.tab, ident).skipAlias(n, c.config)
      else:
        noidentError(c.config, n.sons[1], n)
        result = errorSym(c, n.sons[1])
  of nkClosedSymChoice, nkOpenSymChoice:
    o.mode = oimSymChoice
    if n[0].kind == nkSym:
      result = n.sons[0].sym
    else:
      o.mode = oimDone
      return nil
    o.symChoiceIndex = 1
    o.inSymChoice = initIntSet()
    incl(o.inSymChoice, result.id)
  else: discard
  when false:
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
      result = nextIdentIter(o.it, o.scope.symbols).skipAlias(n, c.config)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = initIdentIter(o.it, o.scope.symbols, o.it.name).skipAlias(n, c.config)
        # BUGFIX: o.it.name <-> n.ident
    else:
      result = nil
  of oimSelfModule:
    result = nextIdentIter(o.it, c.topLevelScope.symbols).skipAlias(n, c.config)
  of oimOtherModule:
    result = nextIdentIter(o.it, o.m.tab).skipAlias(n, c.config)
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
                                   n.sons[0].sym.name, o.inSymChoice).skipAlias(n, c.config)
      while result == nil:
        o.scope = o.scope.parent
        if o.scope == nil: break
        result = firstIdentExcluding(o.it, o.scope.symbols,
                                     n.sons[0].sym.name, o.inSymChoice).skipAlias(n, c.config)
  of oimSymChoiceLocalLookup:
    result = nextIdentExcluding(o.it, o.scope.symbols, o.inSymChoice).skipAlias(n, c.config)
    while result == nil:
      o.scope = o.scope.parent
      if o.scope == nil: break
      result = firstIdentExcluding(o.it, o.scope.symbols,
                                   n.sons[0].sym.name, o.inSymChoice).skipAlias(n, c.config)

  when false:
    if result != nil and result.kind == skStub: loadStub(result)

proc pickSym*(c: PContext, n: PNode; kinds: set[TSymKind];
              flags: TSymFlags = {}): PSym =
  var o: TOverloadIter
  var a = initOverloadIter(o, c, n)
  while a != nil:
    if a.kind in kinds and flags <= a.flags:
      if result == nil: result = a
      else: return nil # ambiguous
    a = nextOverloadIter(o, c, n)

