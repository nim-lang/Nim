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
  renderer, nimfix/prettybase, lineinfos, strutils,
  modulegraphs

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
    of 1: result = considerQuotedIdent(c, n[0], origin)
    else:
      var id = ""
      for i in 0..<n.len:
        let x = n[i]
        case x.kind
        of nkIdent: id.add(x.ident.s)
        of nkSym: id.add(x.sym.name.s)
        of nkLiterals - nkFloatLiterals: id.add(x.renderTree)
        else: handleError(n, origin)
      result = getIdent(c.cache, id)
  of nkOpenSymChoice, nkClosedSymChoice:
    if n[0].kind == nkSym:
      result = n[0].sym.name
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

iterator allScopes(scope: PScope): PScope =
  var current = scope
  while current != nil:
    yield current
    current = current.parent

iterator localScopesFrom*(c: PContext; scope: PScope): PScope =
  for s in allScopes(scope):
    if s == c.topLevelScope: break
    yield s

proc skipAlias*(s: PSym; n: PNode; conf: ConfigRef): PSym =
  if s == nil or s.kind != skAlias:
    result = s
  else:
    result = s.owner
    if conf.cmd == cmdNimfix:
      prettybase.replaceDeprecated(conf, n.info, s, result)
    else:
      message(conf, n.info, warnDeprecated, "use " & result.name.s & " instead; " &
              s.name.s & " is deprecated")

proc isShadowScope*(s: PScope): bool {.inline.} =
  s.parent != nil and s.parent.depthLevel == s.depthLevel

proc localSearchInScope*(c: PContext, s: PIdent): PSym =
  var scope = c.currentScope
  result = strTableGet(scope.symbols, s)
  while result == nil and scope.isShadowScope:
    # We are in a shadow scope, check in the parent too
    scope = scope.parent
    result = strTableGet(scope.symbols, s)

proc initIdentIter(ti: var ModuleIter; marked: var IntSet; im: ImportedModule; name: PIdent;
                   g: ModuleGraph): PSym =
  result = initModuleIter(ti, g, im.m, name)
  while result != nil:
    let b =
      case im.mode
      of importAll: true
      of importSet: result.id in im.imported
      of importExcept: name.id notin im.exceptSet
    if b and not containsOrIncl(marked, result.id):
      return result
    result = nextModuleIter(ti, g)

proc nextIdentIter(ti: var ModuleIter; marked: var IntSet; im: ImportedModule;
                   g: ModuleGraph): PSym =
  while true:
    result = nextModuleIter(ti, g)
    if result == nil: return nil
    case im.mode
    of importAll:
      if not containsOrIncl(marked, result.id):
        return result
    of importSet:
      if result.id in im.imported and not containsOrIncl(marked, result.id):
        return result
    of importExcept:
      if result.name.id notin im.exceptSet and not containsOrIncl(marked, result.id):
        return result

iterator symbols(im: ImportedModule; marked: var IntSet; name: PIdent; g: ModuleGraph): PSym =
  var ti: ModuleIter
  var candidate = initIdentIter(ti, marked, im, name, g)
  while candidate != nil:
    yield candidate
    candidate = nextIdentIter(ti, marked, im, g)

iterator importedItems*(c: PContext; name: PIdent): PSym =
  var marked = initIntSet()
  for im in c.imports.mitems:
    for s in symbols(im, marked, name, c.graph):
      yield s

proc allPureEnumFields(c: PContext; name: PIdent): seq[PSym] =
  var ti: TIdentIter
  result = @[]
  var res = initIdentIter(ti, c.pureEnumFields, name)
  while res != nil:
    result.add res
    res = nextIdentIter(ti, c.pureEnumFields)

iterator allSyms*(c: PContext): (PSym, int, bool) =
  # really iterate over all symbols in all the scopes. This is expensive
  # and only used by suggest.nim.
  var isLocal = true
  var scopeN = 0
  for scope in allScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    dec scopeN
    for item in scope.symbols:
      yield (item, scopeN, isLocal)

  dec scopeN
  isLocal = false
  for im in c.imports.mitems:
    for s in modulegraphs.allSyms(c.graph, im.m):
      assert s != nil
      yield (s, scopeN, isLocal)

proc someSymFromImportTable*(c: PContext; name: PIdent; ambiguous: var bool): PSym =
  var marked = initIntSet()
  result = nil
  for im in c.imports.mitems:
    for s in symbols(im, marked, name, c.graph):
      if result == nil:
        result = s
      else:
        if s.kind notin OverloadableSyms or result.kind notin OverloadableSyms:
          ambiguous = true

proc searchInScopes*(c: PContext, s: PIdent; ambiguous: var bool): PSym =
  for scope in allScopes(c.currentScope):
    result = strTableGet(scope.symbols, s)
    if result != nil: return result
  result = someSymFromImportTable(c, s, ambiguous)

proc debugScopes*(c: PContext; limit=0) {.deprecated.} =
  var i = 0
  for scope in allScopes(c.currentScope):
    echo "scope ", i
    for h in 0..high(scope.symbols.data):
      if scope.symbols.data[h] != nil:
        echo scope.symbols.data[h].name.s
    if i == limit: break
    inc i

proc searchInScopesFilterBy*(c: PContext, s: PIdent, filter: TSymKinds): seq[PSym] =
  result = @[]
  for scope in allScopes(c.currentScope):
    var ti: TIdentIter
    var candidate = initIdentIter(ti, scope.symbols, s)
    while candidate != nil:
      if candidate.kind in filter:
        if result.len == 0:
          result.add candidate
      candidate = nextIdentIter(ti, scope.symbols)

  if result.len == 0:
    var marked = initIntSet()
    for im in c.imports.mitems:
      for s in symbols(im, marked, s, c.graph):
        if s.kind in filter:
          result.add s

proc errorSym*(c: PContext, n: PNode): PSym =
  ## creates an error symbol to avoid cascading errors (for IDE support)
  var m = n
  # ensure that 'considerQuotedIdent' can't fail:
  if m.kind == nkDotExpr: m = m[1]
  let ident = if m.kind in {nkIdent, nkSym, nkAccQuoted}:
      considerQuotedIdent(c, m)
    else:
      getIdent(c.cache, "err:" & renderTree(m))
  result = newSym(skError, ident, nextSymId(c.idgen), getCurrOwner(c), n.info, {})
  result.typ = errorType(c)
  incl(result.flags, sfDiscardable)
  # pretend it's from the top level scope to prevent cascading errors:
  if c.config.cmd != cmdInteractive and c.compilesContextId == 0:
    c.moduleScope.addSym(result)

type
  TOverloadIterMode* = enum
    oimDone, oimNoQualifier, oimSelfModule, oimOtherModule, oimSymChoice,
    oimSymChoiceLocalLookup
  TOverloadIter* = object
    it*: TIdentIter
    mit*: ModuleIter
    m*: PSym
    mode*: TOverloadIterMode
    symChoiceIndex*: int
    currentScope: PScope
    importIdx: int
    marked: IntSet

proc getSymRepr*(conf: ConfigRef; s: PSym, getDeclarationPath = true): string =
  case s.kind
  of routineKinds, skType:
    result = getProcHeader(conf, s, getDeclarationPath = getDeclarationPath)
  else:
    result = "'$1'" % s.name.s
    if getDeclarationPath:
      result.addDeclaredLoc(conf, s)

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
            getSymRepr(c.config, s, getDeclarationPath=false))
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
    if c.module != nil: exportSym(c, sym)
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

proc openShadowScope*(c: PContext) =
  c.currentScope = PScope(parent: c.currentScope,
                          symbols: newStrTable(),
                          depthLevel: c.scopeDepth)

proc closeShadowScope*(c: PContext) =
  c.closeScope

proc mergeShadowScope*(c: PContext) =
  let shadowScope = c.currentScope
  c.rawCloseScope
  for sym in shadowScope.symbols:
    if sym.kind in OverloadableSyms:
      c.addInterfaceOverloadableSymAt(c.currentScope, sym)
    else:
      c.addInterfaceDecl(sym)

when defined(nimfix):
  # when we cannot find the identifier, retry with a changed identifier:
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

proc errorUseQualifier(c: PContext; info: TLineInfo; s: PSym; amb: var bool): PSym =
  var err = "ambiguous identifier: '" & s.name.s & "'"
  var i = 0
  var ignoredModules = 0
  for candidate in importedItems(c, s.name):
    if i == 0: err.add " -- use one of the following:\n"
    else: err.add "\n"
    err.add "  " & candidate.owner.name.s & "." & candidate.name.s
    err.add ": " & typeToString(candidate.typ)
    if candidate.kind == skModule:
      inc ignoredModules
    else:
      result = candidate
    inc i
  if ignoredModules != i-1:
    localError(c.config, info, errGenerated, err)
    result = nil
  else:
    amb = false

proc errorUseQualifier*(c: PContext; info: TLineInfo; s: PSym) =
  var amb: bool
  discard errorUseQualifier(c, info, s, amb)

proc errorUseQualifier(c: PContext; info: TLineInfo; candidates: seq[PSym]) =
  var err = "ambiguous identifier: '" & candidates[0].name.s & "'"
  var i = 0
  for candidate in candidates:
    if i == 0: err.add " -- use one of the following:\n"
    else: err.add "\n"
    err.add "  " & candidate.owner.name.s & "." & candidate.name.s
    err.add ": " & typeToString(candidate.typ)
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
  var amb = false
  case n.kind
  of nkIdent:
    result = searchInScopes(c, n.ident, amb).skipAlias(n, c.config)
    if result == nil:
      fixSpelling(n, n.ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, n.ident.s)
      result = errorSym(c, n)
  of nkSym:
    result = n.sym
  of nkAccQuoted:
    var ident = considerQuotedIdent(c, n)
    result = searchInScopes(c, ident, amb).skipAlias(n, c.config)
    if result == nil:
      fixSpelling(n, ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, ident.s)
      result = errorSym(c, n)
  else:
    internalError(c.config, n.info, "lookUp")
    return
  if amb:
    #contains(c.ambiguousSymbols, result.id):
    result = errorUseQualifier(c, n.info, result, amb)
  when false:
    if result.kind == skStub: loadStub(result)

type
  TLookupFlag* = enum
    checkAmbiguity, checkUndeclared, checkModule, checkPureEnumFields

proc qualifiedLookUp*(c: PContext, n: PNode, flags: set[TLookupFlag]): PSym =
  const allExceptModule = {low(TSymKind)..high(TSymKind)} - {skModule, skPackage}
  case n.kind
  of nkIdent, nkAccQuoted:
    var amb = false
    var ident = considerQuotedIdent(c, n)
    if checkModule in flags:
      result = searchInScopes(c, ident, amb).skipAlias(n, c.config)
    else:
      let candidates = searchInScopesFilterBy(c, ident, allExceptModule) #.skipAlias(n, c.config)
      if candidates.len > 0:
        result = candidates[0]
        amb = candidates.len > 1
        if amb and checkAmbiguity in flags:
          errorUseQualifier(c, n.info, candidates)
    if result == nil:
      let candidates = allPureEnumFields(c, ident)
      if candidates.len > 0:
        result = candidates[0]
        amb = candidates.len > 1
        if amb and checkAmbiguity in flags:
          errorUseQualifier(c, n.info, candidates)

    if result == nil and checkUndeclared in flags:
      fixSpelling(n, ident, searchInScopes)
      errorUndeclaredIdentifier(c, n.info, ident.s)
      result = errorSym(c, n)
    elif checkAmbiguity in flags and result != nil and amb:
      result = errorUseQualifier(c, n.info, result, amb)
    c.isAmbiguous = amb
  of nkSym:
    result = n.sym
  of nkDotExpr:
    result = nil
    var m = qualifiedLookUp(c, n[0], (flags * {checkUndeclared}) + {checkModule})
    if m != nil and m.kind == skModule:
      var ident: PIdent = nil
      if n[1].kind == nkIdent:
        ident = n[1].ident
      elif n[1].kind == nkAccQuoted:
        ident = considerQuotedIdent(c, n[1])
      if ident != nil:
        if m == c.module:
          result = strTableGet(c.topLevelScope.symbols, ident).skipAlias(n, c.config)
        else:
          result = someSym(c.graph, m, ident).skipAlias(n, c.config)
        if result == nil and checkUndeclared in flags:
          fixSpelling(n[1], ident, searchInScopes)
          errorUndeclaredIdentifier(c, n[1].info, ident.s)
          result = errorSym(c, n[1])
      elif n[1].kind == nkSym:
        result = n[1].sym
      elif checkUndeclared in flags and
           n[1].kind notin {nkOpenSymChoice, nkClosedSymChoice}:
        localError(c.config, n[1].info, "identifier expected, but got: " &
                   renderTree(n[1]))
        result = errorSym(c, n[1])
  else:
    result = nil
  when false:
    if result != nil and result.kind == skStub: loadStub(result)

proc initOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  o.importIdx = -1
  o.marked = initIntSet()
  case n.kind
  of nkIdent, nkAccQuoted:
    var ident = considerQuotedIdent(c, n)
    var scope = c.currentScope
    o.mode = oimNoQualifier
    while true:
      result = initIdentIter(o.it, scope.symbols, ident).skipAlias(n, c.config)
      if result != nil:
        o.currentScope = scope
        break
      else:
        scope = scope.parent
        if scope == nil:
          for i in 0..c.imports.high:
            result = initIdentIter(o.mit, o.marked, c.imports[i], ident, c.graph).skipAlias(n, c.config)
            if result != nil:
              o.currentScope = nil
              o.importIdx = i
              return result
          return nil

  of nkSym:
    result = n.sym
    o.mode = oimDone
  of nkDotExpr:
    o.mode = oimOtherModule
    o.m = qualifiedLookUp(c, n[0], {checkUndeclared, checkModule})
    if o.m != nil and o.m.kind == skModule:
      var ident: PIdent = nil
      if n[1].kind == nkIdent:
        ident = n[1].ident
      elif n[1].kind == nkAccQuoted:
        ident = considerQuotedIdent(c, n[1], n)
      if ident != nil:
        if o.m == c.module:
          # a module may access its private members:
          result = initIdentIter(o.it, c.topLevelScope.symbols,
                                 ident).skipAlias(n, c.config)
          o.mode = oimSelfModule
        else:
          result = initModuleIter(o.mit, c.graph, o.m, ident).skipAlias(n, c.config)
      else:
        noidentError(c.config, n[1], n)
        result = errorSym(c, n[1])
  of nkClosedSymChoice, nkOpenSymChoice:
    o.mode = oimSymChoice
    if n[0].kind == nkSym:
      result = n[0].sym
    else:
      o.mode = oimDone
      return nil
    o.symChoiceIndex = 1
    o.marked = initIntSet()
    incl(o.marked, result.id)
  else: discard
  when false:
    if result != nil and result.kind == skStub: loadStub(result)

proc lastOverloadScope*(o: TOverloadIter): int =
  case o.mode
  of oimNoQualifier:
    result = if o.importIdx >= 0: 0
             elif o.currentScope.isNil: -1
             else: o.currentScope.depthLevel
  of oimSelfModule:  result = 1
  of oimOtherModule: result = 0
  else: result = -1

proc nextOverloadIterImports(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  assert o.currentScope == nil
  var idx = o.importIdx+1
  o.importIdx = c.imports.len # assume the other imported modules lack this symbol too
  while idx < c.imports.len:
    result = initIdentIter(o.mit, o.marked, c.imports[idx], o.it.name, c.graph).skipAlias(n, c.config)
    if result != nil:
      # oh, we were wrong, some other module had the symbol, so remember that:
      o.importIdx = idx
      break
    inc idx

proc symChoiceExtension(o: var TOverloadIter; c: PContext; n: PNode): PSym =
  assert o.currentScope == nil
  while o.importIdx < c.imports.len:
    result = initIdentIter(o.mit, o.marked, c.imports[o.importIdx], o.it.name, c.graph).skipAlias(n, c.config)
    #while result != nil and result.id in o.marked:
    #  result = nextIdentIter(o.it, o.marked, c.imports[o.importIdx])
    if result != nil:
      #assert result.id notin o.marked
      return result
    inc o.importIdx

proc nextOverloadIter*(o: var TOverloadIter, c: PContext, n: PNode): PSym =
  case o.mode
  of oimDone:
    result = nil
  of oimNoQualifier:
    if o.currentScope != nil:
      assert o.importIdx < 0
      result = nextIdentIter(o.it, o.currentScope.symbols).skipAlias(n, c.config)
      while result == nil:
        o.currentScope = o.currentScope.parent
        if o.currentScope != nil:
          result = initIdentIter(o.it, o.currentScope.symbols, o.it.name).skipAlias(n, c.config)
          # BUGFIX: o.it.name <-> n.ident
        else:
          o.importIdx = 0
          if c.imports.len > 0:
            result = initIdentIter(o.mit, o.marked, c.imports[o.importIdx], o.it.name, c.graph).skipAlias(n, c.config)
            if result == nil:
              result = nextOverloadIterImports(o, c, n)
          break
    elif o.importIdx < c.imports.len:
      result = nextIdentIter(o.mit, o.marked, c.imports[o.importIdx], c.graph).skipAlias(n, c.config)
      if result == nil:
        result = nextOverloadIterImports(o, c, n)
    else:
      result = nil
  of oimSelfModule:
    result = nextIdentIter(o.it, c.topLevelScope.symbols).skipAlias(n, c.config)
  of oimOtherModule:
    result = nextModuleIter(o.mit, c.graph).skipAlias(n, c.config)
  of oimSymChoice:
    if o.symChoiceIndex < n.len:
      result = n[o.symChoiceIndex].sym
      incl(o.marked, result.id)
      inc o.symChoiceIndex
    elif n.kind == nkOpenSymChoice:
      # try 'local' symbols too for Koenig's lookup:
      o.mode = oimSymChoiceLocalLookup
      o.currentScope = c.currentScope
      result = firstIdentExcluding(o.it, o.currentScope.symbols,
                                   n[0].sym.name, o.marked).skipAlias(n, c.config)
      while result == nil:
        o.currentScope = o.currentScope.parent
        if o.currentScope != nil:
          result = firstIdentExcluding(o.it, o.currentScope.symbols,
                                      n[0].sym.name, o.marked).skipAlias(n, c.config)
        else:
          o.importIdx = 0
          result = symChoiceExtension(o, c, n)
          break
      if result != nil:
        incl o.marked, result.id
  of oimSymChoiceLocalLookup:
    if o.currentScope != nil:
      result = nextIdentExcluding(o.it, o.currentScope.symbols, o.marked).skipAlias(n, c.config)
      while result == nil:
        o.currentScope = o.currentScope.parent
        if o.currentScope != nil:
          result = firstIdentExcluding(o.it, o.currentScope.symbols,
                                      n[0].sym.name, o.marked).skipAlias(n, c.config)
        else:
          o.importIdx = 0
          result = symChoiceExtension(o, c, n)
          break
      if result != nil:
        incl o.marked, result.id

    elif o.importIdx < c.imports.len:
      result = nextIdentIter(o.mit, o.marked, c.imports[o.importIdx], c.graph).skipAlias(n, c.config)
      #assert result.id notin o.marked
      #while result != nil and result.id in o.marked:
      #  result = nextIdentIter(o.it, c.imports[o.importIdx]).skipAlias(n, c.config)
      if result == nil:
        inc o.importIdx
        result = symChoiceExtension(o, c, n)

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

