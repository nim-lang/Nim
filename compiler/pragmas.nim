#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements semantic checking for pragmas

import
  os, platform, condsyms, ast, astalgo, idents, semdata, msgs, renderer,
  wordrecg, ropes, options, strutils, extccomp, math, magicsys, trees,
  types, lookups, lineinfos, pathutils

const
  FirstCallConv* = wNimcall
  LastCallConv* = wNoconv

const
  procPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl,
    wMagic, wNosideeffect, wSideeffect, wNoreturn, wDynlib, wHeader,
    wCompilerProc, wNonReloadable, wCore, wProcVar, wDeprecated, wVarargs, wCompileTime, wMerge,
    wBorrow, wExtern, wImportCompilerProc, wThread, wImportCpp, wImportObjC,
    wAsmNoStackFrame, wError, wDiscardable, wNoInit, wCodegenDecl,
    wGensym, wInject, wRaises, wTags, wLocks, wDelegator, wGcSafe,
    wConstructor, wExportNims, wUsed, wLiftLocals, wStacktrace, wLinetrace}
  converterPragmas* = procPragmas
  methodPragmas* = procPragmas+{wBase}-{wImportCpp}
  templatePragmas* = {wImmediate, wDeprecated, wError, wGensym, wInject, wDirty,
    wDelegator, wExportNims, wUsed, wPragma}
  macroPragmas* = {FirstCallConv..LastCallConv, wImmediate, wImportc, wExportc,
    wNodecl, wMagic, wNosideeffect, wCompilerProc, wNonReloadable, wCore, wDeprecated, wExtern,
    wImportCpp, wImportObjC, wError, wDiscardable, wGensym, wInject, wDelegator,
    wExportNims, wUsed}
  iteratorPragmas* = {FirstCallConv..LastCallConv, wNosideeffect, wSideeffect,
    wImportc, wExportc, wNodecl, wMagic, wDeprecated, wBorrow, wExtern,
    wImportCpp, wImportObjC, wError, wDiscardable, wGensym, wInject, wRaises,
    wTags, wLocks, wGcSafe, wExportNims, wUsed}
  exprPragmas* = {wLine, wLocks, wNoRewrite, wGcSafe, wNosideeffect}
  stmtPragmas* = {wChecks, wObjChecks, wFieldChecks, wRangechecks,
    wBoundchecks, wOverflowchecks, wNilchecks, wMovechecks, wAssertions,
    wWarnings, wHints,
    wLinedir, wStacktrace, wLinetrace, wOptimization, wHint, wWarning, wError,
    wFatal, wDefine, wUndef, wCompile, wLink, wLinksys, wPure, wPush, wPop,
    wBreakpoint, wWatchPoint, wPassl, wPassc,
    wDeadCodeElimUnused,  # deprecated, always on
    wDeprecated,
    wFloatchecks, wInfChecks, wNanChecks, wPragma, wEmit, wUnroll,
    wLinearScanEnd, wPatterns, wTrMacros, wEffects, wNoForward, wReorder, wComputedGoto,
    wInjectStmt, wDeprecated, wExperimental, wThis}
  lambdaPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl,
    wNosideeffect, wSideeffect, wNoreturn, wDynlib, wHeader,
    wDeprecated, wExtern, wThread, wImportCpp, wImportObjC, wAsmNoStackFrame,
    wRaises, wLocks, wTags, wGcSafe, wCodegenDecl}
  typePragmas* = {wImportc, wExportc, wDeprecated, wMagic, wAcyclic, wNodecl,
    wPure, wHeader, wCompilerProc, wCore, wFinal, wSize, wExtern, wShallow,
    wImportCpp, wImportObjC, wError, wIncompleteStruct, wByCopy, wByRef,
    wInheritable, wGensym, wInject, wRequiresInit, wUnchecked, wUnion, wPacked,
    wBorrow, wGcSafe, wExportNims, wPartial, wUsed, wExplain, wPackage}
  fieldPragmas* = {wImportc, wExportc, wDeprecated, wExtern,
    wImportCpp, wImportObjC, wError, wGuard, wBitsize, wUsed}
  varPragmas* = {wImportc, wExportc, wVolatile, wRegister, wThreadVar, wNodecl,
    wMagic, wHeader, wDeprecated, wCompilerProc, wCore, wDynlib, wExtern,
    wImportCpp, wImportObjC, wError, wNoInit, wCompileTime, wGlobal,
    wGensym, wInject, wCodegenDecl, wGuard, wGoto, wExportNims, wUsed, wCursor}
  constPragmas* = {wImportc, wExportc, wHeader, wDeprecated, wMagic, wNodecl,
    wExtern, wImportCpp, wImportObjC, wError, wGensym, wInject, wExportNims,
    wIntDefine, wStrDefine, wBoolDefine, wUsed, wCompilerProc, wCore}
  letPragmas* = varPragmas
  procTypePragmas* = {FirstCallConv..LastCallConv, wVarargs, wNosideeffect,
                      wThread, wRaises, wLocks, wTags, wGcSafe}
  forVarPragmas* = {wInject, wGensym}
  allRoutinePragmas* = methodPragmas + iteratorPragmas + lambdaPragmas
  enumFieldPragmas* = {wDeprecated}

proc getPragmaVal*(procAst: PNode; name: TSpecialWord): PNode =
  let p = procAst[pragmasPos]
  if p.kind == nkEmpty: return nil
  for it in p:
    if it.kind in nkPragmaCallKinds and it.len == 2 and it[0].kind == nkIdent and
        it[0].ident.id == ord(name):
      return it[1]

proc pragma*(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords)

proc recordPragma(c: PContext; n: PNode; key, val: string; val2 = "") =
  var recorded = newNodeI(nkCommentStmt, n.info)
  recorded.add newStrNode(key, n.info)
  recorded.add newStrNode(val, n.info)
  if val2.len > 0: recorded.add newStrNode(val2, n.info)
  c.graph.recordStmt(c.graph, c.module, recorded)

const
  errStringLiteralExpected = "string literal expected"
  errIntLiteralExpected = "integer literal expected"

proc invalidPragma*(c: PContext; n: PNode) =
  localError(c.config, n.info, "invalid pragma: " & renderTree(n, {renderNoComments}))
proc illegalCustomPragma*(c: PContext, n: PNode, s: PSym) =
  localError(c.config, n.info, "cannot attach a custom pragma to '" & s.name.s & "'")

proc pragmaAsm*(c: PContext, n: PNode): char =
  result = '\0'
  if n != nil:
    for i in 0 ..< sonsLen(n):
      let it = n.sons[i]
      if it.kind in nkPragmaCallKinds and it.len == 2 and it.sons[0].kind == nkIdent:
        case whichKeyword(it.sons[0].ident)
        of wSubsChar:
          if it.sons[1].kind == nkCharLit: result = chr(int(it.sons[1].intVal))
          else: invalidPragma(c, it)
        else: invalidPragma(c, it)
      else:
        invalidPragma(c, it)

proc setExternName(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  # special cases to improve performance:
  if extname == "$1":
    s.loc.r = rope(s.name.s)
  elif '$' notin extname:
    s.loc.r = rope(extname)
  else:
    try:
      s.loc.r = rope(extname % s.name.s)
    except ValueError:
      localError(c.config, info, "invalid extern name: '" & extname & "'. (Forgot to escape '$'?)")
  if c.config.cmd == cmdPretty and '$' notin extname:
    # note that '{.importc.}' is transformed into '{.importc: "$1".}'
    s.loc.flags.incl(lfFullExternalName)

proc makeExternImport(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  setExternName(c, s, extname, info)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)

proc makeExternExport(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  setExternName(c, s, extname, info)
  incl(s.flags, sfExportc)

proc processImportCompilerProc(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  setExternName(c, s, extname, info)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)
  incl(s.loc.flags, lfImportCompilerProc)

proc processImportCpp(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  setExternName(c, s, extname, info)
  incl(s.flags, sfImportc)
  incl(s.flags, sfInfixCall)
  excl(s.flags, sfForward)
  if c.config.cmd == cmdCompileToC:
    let m = s.getModule()
    incl(m.flags, sfCompileToCpp)
  incl c.config.globalOptions, optMixedMode

proc processImportObjC(c: PContext; s: PSym, extname: string, info: TLineInfo) =
  setExternName(c, s, extname, info)
  incl(s.flags, sfImportc)
  incl(s.flags, sfNamedParamCall)
  excl(s.flags, sfForward)
  let m = s.getModule()
  incl(m.flags, sfCompileToObjC)

proc newEmptyStrNode(c: PContext; n: PNode): PNode {.noinline.} =
  result = newNodeIT(nkStrLit, n.info, getSysType(c.graph, n.info, tyString))
  result.strVal = ""

proc getStrLitNode(c: PContext, n: PNode): PNode =
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    localError(c.config, n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(c, n)
  else:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit: result = n.sons[1]
    else:
      localError(c.config, n.info, errStringLiteralExpected)
      # error correction:
      result = newEmptyStrNode(c, n)

proc expectStrLit(c: PContext, n: PNode): string =
  result = getStrLitNode(c, n).strVal

proc expectIntLit(c: PContext, n: PNode): int =
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    localError(c.config, n.info, errIntLiteralExpected)
  else:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkIntLit..nkInt64Lit: result = int(n.sons[1].intVal)
    else: localError(c.config, n.info, errIntLiteralExpected)

proc getOptionalStr(c: PContext, n: PNode, defaultStr: string): string =
  if n.kind in nkPragmaCallKinds: result = expectStrLit(c, n)
  else: result = defaultStr

proc processCodegenDecl(c: PContext, n: PNode, sym: PSym) =
  sym.constraint = getStrLitNode(c, n)

proc processMagic(c: PContext, n: PNode, s: PSym) =
  #if sfSystemModule notin c.module.flags:
  #  liMessage(n.info, errMagicOnlyInSystem)
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    localError(c.config, n.info, errStringLiteralExpected)
    return
  var v: string
  if n.sons[1].kind == nkIdent: v = n.sons[1].ident.s
  else: v = expectStrLit(c, n)
  for m in low(TMagic) .. high(TMagic):
    if substr($m, 1) == v:
      s.magic = m
      break
  if s.magic == mNone: message(c.config, n.info, warnUnknownMagic, v)

proc wordToCallConv(sw: TSpecialWord): TCallingConvention =
  # this assumes that the order of special words and calling conventions is
  # the same
  result = TCallingConvention(ord(ccDefault) + ord(sw) - ord(wNimcall))

proc isTurnedOn(c: PContext, n: PNode): bool =
  if n.kind in nkPragmaCallKinds and n.len == 2:
    let x = c.semConstBoolExpr(c, n.sons[1])
    n.sons[1] = x
    if x.kind == nkIntLit: return x.intVal != 0
  localError(c.config, n.info, "'on' or 'off' expected")

proc onOff(c: PContext, n: PNode, op: TOptions, resOptions: var TOptions) =
  if isTurnedOn(c, n): resOptions = resOptions + op
  else: resOptions = resOptions - op

proc pragmaNoForward(c: PContext, n: PNode; flag=sfNoForward) =
  if isTurnedOn(c, n):
    incl(c.module.flags, flag)
    c.features.incl codeReordering
  else:
    excl(c.module.flags, flag)
    # c.features.excl codeReordering

  # deprecated as of 0.18.1
  message(c.config, n.info, warnDeprecated,
          "use {.experimental: \"codeReordering\".} instead; " &
          (if flag == sfNoForward: "{.noForward.}" else: "{.reorder.}") & " is deprecated")

proc processCallConv(c: PContext, n: PNode) =
  if n.kind in nkPragmaCallKinds and n.len == 2 and n.sons[1].kind == nkIdent:
    let sw = whichKeyword(n.sons[1].ident)
    case sw
    of FirstCallConv..LastCallConv:
      c.optionStack[^1].defaultCC = wordToCallConv(sw)
    else: localError(c.config, n.info, "calling convention expected")
  else:
    localError(c.config, n.info, "calling convention expected")

proc getLib(c: PContext, kind: TLibKind, path: PNode): PLib =
  for it in c.libs:
    if it.kind == kind and trees.exprStructuralEquivalent(it.path, path):
      return it

  result = newLib(kind)
  result.path = path
  c.libs.add result
  if path.kind in {nkStrLit..nkTripleStrLit}:
    result.isOverriden = options.isDynlibOverride(c.config, path.strVal)

proc expectDynlibNode(c: PContext, n: PNode): PNode =
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    localError(c.config, n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(c, n)
  else:
    # For the OpenGL wrapper we support:
    # {.dynlib: myGetProcAddr(...).}
    result = c.semExpr(c, n.sons[1])
    if result.kind == nkSym and result.sym.kind == skConst:
      result = result.sym.ast # look it up
    if result.typ == nil or result.typ.kind notin {tyPointer, tyString, tyProc}:
      localError(c.config, n.info, errStringLiteralExpected)
      result = newEmptyStrNode(c, n)

proc processDynLib(c: PContext, n: PNode, sym: PSym) =
  if (sym == nil) or (sym.kind == skModule):
    let lib = getLib(c, libDynamic, expectDynlibNode(c, n))
    if not lib.isOverriden:
      c.optionStack[^1].dynlib = lib
  else:
    if n.kind in nkPragmaCallKinds:
      var lib = getLib(c, libDynamic, expectDynlibNode(c, n))
      if not lib.isOverriden:
        addToLib(lib, sym)
        incl(sym.loc.flags, lfDynamicLib)
    else:
      incl(sym.loc.flags, lfExportLib)
    # since we'll be loading the dynlib symbols dynamically, we must use
    # a calling convention that doesn't introduce custom name mangling
    # cdecl is the default - the user can override this explicitly
    if sym.kind in routineKinds and sym.typ != nil and
        sym.typ.callConv == ccDefault:
      sym.typ.callConv = ccCDecl

proc processNote(c: PContext, n: PNode) =
  if n.kind in nkPragmaCallKinds and len(n) == 2 and
      n[0].kind == nkBracketExpr and
      n[0].len == 2 and
      n[0][1].kind == nkIdent and n[0][0].kind == nkIdent:
    var nk: TNoteKind
    case whichKeyword(n[0][0].ident)
    of wHint:
      var x = findStr(HintsToStr, n[0][1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(hintMin))
      else: invalidPragma(c, n); return
    of wWarning:
      var x = findStr(WarningsToStr, n[0][1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(warnMin))
      else: invalidPragma(c, n); return
    else:
      invalidPragma(c, n)
      return

    let x = c.semConstBoolExpr(c, n[1])
    n.sons[1] = x
    if x.kind == nkIntLit and x.intVal != 0: incl(c.config.notes, nk)
    else: excl(c.config.notes, nk)
  else:
    invalidPragma(c, n)

proc pragmaToOptions(w: TSpecialWord): TOptions {.inline.} =
  case w
  of wChecks: ChecksOptions
  of wObjChecks: {optObjCheck}
  of wFieldChecks: {optFieldCheck}
  of wRangechecks: {optRangeCheck}
  of wBoundchecks: {optBoundsCheck}
  of wOverflowchecks: {optOverflowCheck}
  of wNilchecks: {optNilCheck}
  of wFloatchecks: {optNaNCheck, optInfCheck}
  of wNanChecks: {optNaNCheck}
  of wInfChecks: {optInfCheck}
  of wMovechecks: {optMoveCheck}
  of wAssertions: {optAssert}
  of wWarnings: {optWarns}
  of wHints: {optHints}
  of wLinedir: {optLineDir}
  of wStacktrace: {optStackTrace}
  of wLinetrace: {optLineTrace}
  of wDebugger: {optEndb}
  of wProfiler: {optProfiler, optMemTracker}
  of wMemTracker: {optMemTracker}
  of wByRef: {optByRef}
  of wImplicitStatic: {optImplicitStatic}
  of wPatterns, wTrMacros: {optTrMacros}
  else: {}

proc processExperimental(c: PContext; n: PNode) =
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    c.features.incl oldExperimentalFeatures
  else:
    n[1] = c.semConstExpr(c, n[1])
    case n[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit:
      try:
        let feature = parseEnum[Feature](n[1].strVal)
        c.features.incl feature
        if feature == codeReordering:
          if not isTopLevel(c):
              localError(c.config, n.info,
                         "Code reordering experimental pragma only valid at toplevel")
          c.module.flags.incl sfReorder
      except ValueError:
        localError(c.config, n[1].info, "unknown experimental feature")
    else:
      localError(c.config, n.info, errStringLiteralExpected)

proc tryProcessOption(c: PContext, n: PNode, resOptions: var TOptions): bool =
  result = true
  if n.kind notin nkPragmaCallKinds or n.len != 2: result = false
  elif n.sons[0].kind == nkBracketExpr: processNote(c, n)
  elif n.sons[0].kind != nkIdent: result = false
  else:
    let sw = whichKeyword(n.sons[0].ident)
    if sw == wExperimental:
      processExperimental(c, n)
      return true
    let opts = pragmaToOptions(sw)
    if opts != {}:
      onOff(c, n, opts, resOptions)
    else:
      case sw
      of wCallconv: processCallConv(c, n)
      of wDynlib: processDynLib(c, n, nil)
      of wOptimization:
        if n.sons[1].kind != nkIdent:
          invalidPragma(c, n)
        else:
          case n.sons[1].ident.s.normalize
          of "speed":
            incl(resOptions, optOptimizeSpeed)
            excl(resOptions, optOptimizeSize)
          of "size":
            excl(resOptions, optOptimizeSpeed)
            incl(resOptions, optOptimizeSize)
          of "none":
            excl(resOptions, optOptimizeSpeed)
            excl(resOptions, optOptimizeSize)
          else: localError(c.config, n.info, "'none', 'speed' or 'size' expected")
      else: result = false

proc processOption(c: PContext, n: PNode, resOptions: var TOptions) =
  if not tryProcessOption(c, n, resOptions):
    # calling conventions (boring...):
    localError(c.config, n.info, "option expected")

proc processPush(c: PContext, n: PNode, start: int) =
  if n.sons[start-1].kind in nkPragmaCallKinds:
    localError(c.config, n.info, "'push' cannot have arguments")
  var x = newOptionEntry(c.config)
  var y = c.optionStack[^1]
  x.options = c.config.options
  x.defaultCC = y.defaultCC
  x.dynlib = y.dynlib
  x.notes = c.config.notes
  x.features = c.features
  c.optionStack.add(x)
  for i in start ..< sonsLen(n):
    if not tryProcessOption(c, n.sons[i], c.config.options):
      # simply store it somewhere:
      if x.otherPragmas.isNil:
        x.otherPragmas = newNodeI(nkPragma, n.info)
      x.otherPragmas.add n.sons[i]
    #localError(c.config, n.info, errOptionExpected)

  # If stacktrace is disabled globally we should not enable it
  if optStackTrace notin c.optionStack[0].options:
    c.config.options.excl(optStackTrace)

proc processPop(c: PContext, n: PNode) =
  if c.optionStack.len <= 1:
    localError(c.config, n.info, "{.pop.} without a corresponding {.push.}")
  else:
    c.config.options = c.optionStack[^1].options
    c.config.notes = c.optionStack[^1].notes
    c.features = c.optionStack[^1].features
    c.optionStack.setLen(c.optionStack.len - 1)

proc processDefine(c: PContext, n: PNode) =
  if (n.kind in nkPragmaCallKinds and n.len == 2) and (n[1].kind == nkIdent):
    defineSymbol(c.config.symbols, n[1].ident.s)
    message(c.config, n.info, warnDeprecated, "define is deprecated")
  else:
    invalidPragma(c, n)

proc processUndef(c: PContext, n: PNode) =
  if (n.kind in nkPragmaCallKinds and n.len == 2) and (n[1].kind == nkIdent):
    undefSymbol(c.config.symbols, n[1].ident.s)
    message(c.config, n.info, warnDeprecated, "undef is deprecated")
  else:
    invalidPragma(c, n)

proc relativeFile(c: PContext; n: PNode; ext=""): AbsoluteFile =
  var s = expectStrLit(c, n)
  if ext.len > 0 and splitFile(s).ext == "":
    s = addFileExt(s, ext)
  result = AbsoluteFile parentDir(toFullPath(c.config, n.info)) / s
  if not fileExists(result):
    if isAbsolute(s): result = AbsoluteFile s
    else:
      result = findFile(c.config, s)
      if result.isEmpty: result = AbsoluteFile s

proc processCompile(c: PContext, n: PNode) =
  proc docompile(c: PContext; it: PNode; src, dest: AbsoluteFile) =
    var cf = Cfile(nimname: splitFile(src).name,
                   cname: src, obj: dest, flags: {CfileFlag.External})
    extccomp.addExternalFileToCompile(c.config, cf)
    recordPragma(c, it, "compile", src.string, dest.string)

  proc getStrLit(c: PContext, n: PNode; i: int): string =
    n.sons[i] = c.semConstExpr(c, n[i])
    case n[i].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit:
      shallowCopy(result, n[i].strVal)
    else:
      localError(c.config, n.info, errStringLiteralExpected)
      result = ""

  let it = if n.kind in nkPragmaCallKinds and n.len == 2: n.sons[1] else: n
  if it.kind in {nkPar, nkTupleConstr} and it.len == 2:
    let s = getStrLit(c, it, 0)
    let dest = getStrLit(c, it, 1)
    var found = parentDir(toFullPath(c.config, n.info)) / s
    for f in os.walkFiles(found):
      let obj = completeCFilePath(c.config, AbsoluteFile(dest % extractFilename(f)))
      docompile(c, it, AbsoluteFile f, obj)
  else:
    let s = expectStrLit(c, n)
    var found = AbsoluteFile(parentDir(toFullPath(c.config, n.info)) / s)
    if not fileExists(found):
      if isAbsolute(s): found = AbsoluteFile s
      else:
        found = findFile(c.config, s)
        if found.isEmpty: found = AbsoluteFile s
    let obj = toObjFile(c.config, completeCFilePath(c.config, found, false))
    docompile(c, it, found, obj)

proc processLink(c: PContext, n: PNode) =
  let found = relativeFile(c, n, CC[c.config.cCompiler].objExt)
  extccomp.addExternalFileToLink(c.config, found)
  recordPragma(c, n, "link", found.string)

proc pragmaBreakpoint(c: PContext, n: PNode) =
  discard getOptionalStr(c, n, "")

proc pragmaWatchpoint(c: PContext, n: PNode) =
  if n.kind in nkPragmaCallKinds and n.len == 2:
    n.sons[1] = c.semExpr(c, n.sons[1])
  else:
    invalidPragma(c, n)

proc semAsmOrEmit*(con: PContext, n: PNode, marker: char): PNode =
  case n.sons[1].kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    result = newNode(if n.kind == nkAsmStmt: nkAsmStmt else: nkArgList, n.info)
    var str = n.sons[1].strVal
    if str == "":
      localError(con.config, n.info, "empty 'asm' statement")
      return
    # now parse the string literal and substitute symbols:
    var a = 0
    while true:
      var b = strutils.find(str, marker, a)
      var sub = if b < 0: substr(str, a) else: substr(str, a, b - 1)
      if sub != "": addSon(result, newStrNode(nkStrLit, sub))
      if b < 0: break
      var c = strutils.find(str, marker, b + 1)
      if c < 0: sub = substr(str, b + 1)
      else: sub = substr(str, b + 1, c - 1)
      if sub != "":
        var e = searchInScopes(con, getIdent(con.cache, sub))
        if e != nil:
          when false:
            if e.kind == skStub: loadStub(e)
          incl(e.flags, sfUsed)
          addSon(result, newSymNode(e))
        else:
          addSon(result, newStrNode(nkStrLit, sub))
      else:
        # an empty '``' produces a single '`'
        addSon(result, newStrNode(nkStrLit, $marker))
      if c < 0: break
      a = c + 1
  else:
    illFormedAstLocal(n, con.config)
    result = newNode(nkAsmStmt, n.info)

proc pragmaEmit(c: PContext, n: PNode) =
  if n.kind notin nkPragmaCallKinds or n.len != 2:
    localError(c.config, n.info, errStringLiteralExpected)
  else:
    let n1 = n[1]
    if n1.kind == nkBracket:
      var b = newNodeI(nkBracket, n1.info, n1.len)
      for i in 0..<n1.len:
        b.sons[i] = c.semExpr(c, n1[i])
      n.sons[1] = b
    else:
      n.sons[1] = c.semConstExpr(c, n1)
      case n.sons[1].kind
      of nkStrLit, nkRStrLit, nkTripleStrLit:
        n.sons[1] = semAsmOrEmit(c, n, '`')
      else:
        localError(c.config, n.info, errStringLiteralExpected)

proc noVal(c: PContext; n: PNode) =
  if n.kind in nkPragmaCallKinds and n.len > 1: invalidPragma(c, n)

proc pragmaUnroll(c: PContext, n: PNode) =
  if c.p.nestedLoopCounter <= 0:
    invalidPragma(c, n)
  elif n.kind in nkPragmaCallKinds and n.len == 2:
    var unrollFactor = expectIntLit(c, n)
    if unrollFactor <% 32:
      n.sons[1] = newIntNode(nkIntLit, unrollFactor)
    else:
      invalidPragma(c, n)

proc pragmaLine(c: PContext, n: PNode) =
  if n.kind in nkPragmaCallKinds and n.len == 2:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    let a = n.sons[1]
    if a.kind in {nkPar, nkTupleConstr}:
      # unpack the tuple
      var x = a.sons[0]
      var y = a.sons[1]
      if x.kind == nkExprColonExpr: x = x.sons[1]
      if y.kind == nkExprColonExpr: y = y.sons[1]
      if x.kind != nkStrLit:
        localError(c.config, n.info, errStringLiteralExpected)
      elif y.kind != nkIntLit:
        localError(c.config, n.info, errIntLiteralExpected)
      else:
        n.info.fileIndex = fileInfoIdx(c.config, AbsoluteFile(x.strVal))
        n.info.line = uint16(y.intVal)
    else:
      localError(c.config, n.info, "tuple expected")
  else:
    # sensible default:
    n.info = getInfoContext(c.config, -1)

proc processPragma(c: PContext, n: PNode, i: int) =
  let it = n[i]
  if it.kind notin nkPragmaCallKinds and it.len == 2: invalidPragma(c, n)
  elif it[0].kind != nkIdent: invalidPragma(c, n)
  elif it[1].kind != nkIdent: invalidPragma(c, n)

  var userPragma = newSym(skTemplate, it[1].ident, nil, it.info, c.config.options)
  userPragma.ast = newNode(nkPragma, n.info, n.sons[i+1..^1])
  strTableAdd(c.userPragmas, userPragma)

proc pragmaRaisesOrTags(c: PContext, n: PNode) =
  proc processExc(c: PContext, x: PNode) =
    var t = skipTypes(c.semTypeNode(c, x, nil), skipPtrs)
    if t.kind != tyObject:
      localError(c.config, x.info, errGenerated, "invalid type for raises/tags list")
    x.typ = t

  if n.kind in nkPragmaCallKinds and n.len == 2:
    let it = n.sons[1]
    if it.kind notin {nkCurly, nkBracket}:
      processExc(c, it)
    else:
      for e in items(it): processExc(c, e)
  else:
    invalidPragma(c, n)

proc pragmaLockStmt(c: PContext; it: PNode) =
  if it.kind notin nkPragmaCallKinds or it.len != 2:
    invalidPragma(c, it)
  else:
    let n = it[1]
    if n.kind != nkBracket:
      localError(c.config, n.info, errGenerated, "locks pragma takes a list of expressions")
    else:
      for i in 0 ..< n.len:
        n.sons[i] = c.semExpr(c, n.sons[i])

proc pragmaLocks(c: PContext, it: PNode): TLockLevel =
  if it.kind notin nkPragmaCallKinds or it.len != 2:
    invalidPragma(c, it)
  else:
    case it[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit:
      if it[1].strVal == "unknown":
        result = UnknownLockLevel
      else:
        localError(c.config, it[1].info, "invalid string literal for locks pragma (only allowed string is \"unknown\")")
    else:
      let x = expectIntLit(c, it)
      if x < 0 or x > MaxLockLevel:
        localError(c.config, it[1].info, "integer must be within 0.." & $MaxLockLevel)
      else:
        result = TLockLevel(x)

proc typeBorrow(c: PContext; sym: PSym, n: PNode) =
  if n.kind in nkPragmaCallKinds and n.len == 2:
    let it = n.sons[1]
    if it.kind != nkAccQuoted:
      localError(c.config, n.info, "a type can only borrow `.` for now")
  incl(sym.typ.flags, tfBorrowDot)

proc markCompilerProc(c: PContext; s: PSym) =
  # minor hack ahead: FlowVar is the only generic .compilerProc type which
  # should not have an external name set:
  if s.kind != skType or s.name.s != "FlowVar":
    makeExternExport(c, s, "$1", s.info)
  incl(s.flags, sfCompilerProc)
  incl(s.flags, sfUsed)
  registerCompilerProc(c.graph, s)

proc deprecatedStmt(c: PContext; outerPragma: PNode) =
  let pragma = outerPragma[1]
  if pragma.kind in {nkStrLit..nkTripleStrLit}:
    incl(c.module.flags, sfDeprecated)
    c.module.constraint = getStrLitNode(c, outerPragma)
    return
  if pragma.kind != nkBracket:
    localError(c.config, pragma.info, "list of key:value pairs expected"); return
  for n in pragma:
    if n.kind in nkPragmaCallKinds and n.len == 2:
      let dest = qualifiedLookUp(c, n[1], {checkUndeclared})
      if dest == nil or dest.kind in routineKinds:
        localError(c.config, n.info, warnUser, "the .deprecated pragma is unreliable for routines")
      let src = considerQuotedIdent(c, n[0])
      let alias = newSym(skAlias, src, dest, n[0].info, c.config.options)
      incl(alias.flags, sfExported)
      if sfCompilerProc in dest.flags: markCompilerProc(c, alias)
      addInterfaceDecl(c, alias)
      n.sons[1] = newSymNode(dest)
    else:
      localError(c.config, n.info, "key:value pair expected")

proc pragmaGuard(c: PContext; it: PNode; kind: TSymKind): PSym =
  if it.kind notin nkPragmaCallKinds or it.len != 2:
    invalidPragma(c, it); return
  let n = it[1]
  if n.kind == nkSym:
    result = n.sym
  elif kind == skField:
    # First check if the guard is a global variable:
    result = qualifiedLookUp(c, n, {})
    if result.isNil or result.kind notin {skLet, skVar} or
        sfGlobal notin result.flags:
      # We return a dummy symbol; later passes over the type will repair it.
      # Generic instantiation needs to know about this too. But we're lazy
      # and perform the lookup on demand instead.
      result = newSym(skUnknown, considerQuotedIdent(c, n), nil, n.info,
        c.config.options)
  else:
    result = qualifiedLookUp(c, n, {checkUndeclared})

proc semCustomPragma(c: PContext, n: PNode): PNode =
  var callNode: PNode

  if n.kind == nkIdent:
    # pragma -> pragma()
    callNode = newTree(nkCall, n)
  elif n.kind == nkExprColonExpr:
    # pragma: arg -> pragma(arg)
    callNode = newTree(nkCall, n[0], n[1])
  elif n.kind in nkPragmaCallKinds:
    callNode = n
  else:
    invalidPragma(c, n)
    return n

  let r = c.semOverloadedCall(c, callNode, n, {skTemplate}, {efNoUndeclared})

  if r.isNil or sfCustomPragma notin r[0].sym.flags:
    invalidPragma(c, n)
    return n

  result = r
  # Transform the nkCall node back to its original form if possible
  if n.kind == nkIdent and r.len == 1:
    # pragma() -> pragma
    result = result[0]
  elif n.kind == nkExprColonExpr and r.len == 2:
    # pragma(arg) -> pragma: arg
    result.kind = n.kind

proc singlePragma(c: PContext, sym: PSym, n: PNode, i: var int,
                  validPragmas: TSpecialWords, comesFromPush: bool) : bool =
  var it = n.sons[i]
  var key = if it.kind in nkPragmaCallKinds and it.len > 1: it.sons[0] else: it
  if key.kind == nkBracketExpr:
    processNote(c, it)
    return
  elif key.kind notin nkIdentKinds:
    n.sons[i] = semCustomPragma(c, it)
    return
  let ident = considerQuotedIdent(c, key)
  var userPragma = strTableGet(c.userPragmas, ident)
  if userPragma != nil:
    # number of pragmas increase/decrease with user pragma expansion
    inc c.instCounter
    if c.instCounter > 100:
      globalError(c.config, it.info, "recursive dependency: " & userPragma.name.s)

    pragma(c, sym, userPragma.ast, validPragmas)
    n.sons[i..i] = userPragma.ast.sons # expand user pragma with its content
    i.inc(userPragma.ast.len - 1) # inc by -1 is ok, user pragmas was empty
    dec c.instCounter
  else:
    let k = whichKeyword(ident)
    if k in validPragmas:
      case k
      of wExportc:
        makeExternExport(c, sym, getOptionalStr(c, it, "$1"), it.info)
        incl(sym.flags, sfUsed) # avoid wrong hints
      of wImportc:
        let name = getOptionalStr(c, it, "$1")
        cppDefine(c.config, name)
        recordPragma(c, it, "cppdefine", name)
        makeExternImport(c, sym, name, it.info)
      of wImportCompilerProc:
        let name = getOptionalStr(c, it, "$1")
        cppDefine(c.config, name)
        recordPragma(c, it, "cppdefine", name)
        processImportCompilerProc(c, sym, name, it.info)
      of wExtern: setExternName(c, sym, expectStrLit(c, it), it.info)
      of wImmediate:
        if sym.kind in {skTemplate, skMacro}:
          incl(sym.flags, sfImmediate)
          incl(sym.flags, sfAllUntyped)
          message(c.config, n.info, warnDeprecated, "use 'untyped' parameters instead; immediate is deprecated")
        else: invalidPragma(c, it)
      of wDirty:
        if sym.kind == skTemplate: incl(sym.flags, sfDirty)
        else: invalidPragma(c, it)
      of wImportCpp:
        processImportCpp(c, sym, getOptionalStr(c, it, "$1"), it.info)
      of wImportObjC:
        processImportObjC(c, sym, getOptionalStr(c, it, "$1"), it.info)
      of wAlign:
        if sym.typ == nil: invalidPragma(c, it)
        var align = expectIntLit(c, it)
        if (not isPowerOfTwo(align) and align != 0) or align >% high(int16):
          localError(c.config, it.info, "power of two expected")
        else:
          sym.typ.align = align.int16
      of wSize:
        if sym.typ == nil: invalidPragma(c, it)
        var size = expectIntLit(c, it)
        case size
        of 1, 2, 4, 8:
          sym.typ.size = size
          if size == 8 and c.config.target.targetCPU == cpuI386:
            sym.typ.align = 4
          else:
            sym.typ.align = int16(size)
        else:
          localError(c.config, it.info, "size may only be 1, 2, 4 or 8")
      of wNodecl:
        noVal(c, it)
        incl(sym.loc.flags, lfNoDecl)
      of wPure, wAsmNoStackFrame:
        noVal(c, it)
        if sym != nil:
          if k == wPure and sym.kind in routineKinds: invalidPragma(c, it)
          else: incl(sym.flags, sfPure)
      of wVolatile:
        noVal(c, it)
        incl(sym.flags, sfVolatile)
      of wRegister:
        noVal(c, it)
        incl(sym.flags, sfRegister)
      of wThreadVar:
        noVal(c, it)
        incl(sym.flags, {sfThread, sfGlobal})
      of wDeadCodeElimUnused: discard  # deprecated, dead code elim always on
      of wNoForward: pragmaNoForward(c, it)
      of wReorder: pragmaNoForward(c, it, flag = sfReorder)
      of wMagic: processMagic(c, it, sym)
      of wCompileTime:
        noVal(c, it)
        incl(sym.flags, sfCompileTime)
        incl(sym.loc.flags, lfNoDecl)
      of wGlobal:
        noVal(c, it)
        incl(sym.flags, sfGlobal)
        incl(sym.flags, sfPure)
      of wMerge:
        # only supported for backwards compat, doesn't do anything anymore
        noVal(c, it)
      of wConstructor:
        noVal(c, it)
        incl(sym.flags, sfConstructor)
      of wHeader:
        var lib = getLib(c, libHeader, getStrLitNode(c, it))
        addToLib(lib, sym)
        incl(sym.flags, sfImportc)
        incl(sym.loc.flags, lfHeader)
        incl(sym.loc.flags, lfNoDecl)
        # implies nodecl, because otherwise header would not make sense
        if sym.loc.r == nil: sym.loc.r = rope(sym.name.s)
      of wNosideeffect:
        noVal(c, it)
        if sym != nil:
          incl(sym.flags, sfNoSideEffect)
          if sym.typ != nil: incl(sym.typ.flags, tfNoSideEffect)
      of wSideeffect:
        noVal(c, it)
        incl(sym.flags, sfSideEffect)
      of wNoreturn:
        noVal(c, it)
        # Disable the 'noreturn' annotation when in the "Quirky Exceptions" mode!
        if not isDefined(c.config, "nimQuirky"):
          incl(sym.flags, sfNoReturn)
        if sym.typ[0] != nil:
          localError(c.config, sym.ast[paramsPos][0].info,
            ".noreturn with return type not allowed")
      of wDynlib:
        processDynLib(c, it, sym)
      of wCompilerProc, wCore:
        noVal(c, it)           # compilerproc may not get a string!
        cppDefine(c.graph.config, sym.name.s)
        recordPragma(c, it, "cppdefine", sym.name.s)
        if sfFromGeneric notin sym.flags: markCompilerProc(c, sym)
      of wNonReloadable:
        sym.flags.incl sfNonReloadable
      of wProcVar:
        noVal(c, it)
        incl(sym.flags, sfProcvar)
      of wExplain:
        sym.flags.incl sfExplain
      of wDeprecated:
        if sym != nil and sym.kind in routineKinds + {skType, skVar, skLet}:
          if it.kind in nkPragmaCallKinds: discard getStrLitNode(c, it)
          incl(sym.flags, sfDeprecated)
        elif sym != nil and sym.kind != skModule:
          # We don't support the extra annotation field
          if it.kind in nkPragmaCallKinds:
            localError(c.config, it.info, "annotation to deprecated not supported here")
          incl(sym.flags, sfDeprecated)
        # At this point we're quite sure this is a statement and applies to the
        # whole module
        elif it.kind in nkPragmaCallKinds: deprecatedStmt(c, it)
        else: incl(c.module.flags, sfDeprecated)
      of wVarargs:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfVarargs)
      of wBorrow:
        if sym.kind == skType:
          typeBorrow(c, sym, it)
        else:
          noVal(c, it)
          incl(sym.flags, sfBorrow)
      of wFinal:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfFinal)
      of wInheritable:
        noVal(c, it)
        if sym.typ == nil or tfFinal in sym.typ.flags: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfInheritable)
      of wPackage:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.flags, sfForward)
      of wAcyclic:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        # now: ignored
      of wShallow:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfShallow)
      of wThread:
        noVal(c, it)
        incl(sym.flags, sfThread)
        incl(sym.flags, sfProcvar)
        if sym.typ != nil:
          incl(sym.typ.flags, tfThread)
          if sym.typ.callConv == ccClosure: sym.typ.callConv = ccDefault
      of wGcSafe:
        noVal(c, it)
        if sym != nil:
          if sym.kind != skType: incl(sym.flags, sfThread)
          if sym.typ != nil: incl(sym.typ.flags, tfGcSafe)
          else: invalidPragma(c, it)
        else:
          discard "no checking if used as a code block"
      of wPacked:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfPacked)
      of wHint:
        let s = expectStrLit(c, it)
        recordPragma(c, it, "hint", s)
        message(c.config, it.info, hintUser, s)
      of wWarning:
        let s = expectStrLit(c, it)
        recordPragma(c, it, "warning", s)
        message(c.config, it.info, warnUser, s)
      of wError:
        if sym != nil and (sym.isRoutine or sym.kind == skType) and wUsed in validPragmas:
          # This is subtle but correct: the error *statement* is only
          # allowed when 'wUsed' is not in validPragmas. Here this is the easiest way to
          # distinguish properly between
          # ``proc p() {.error}`` and ``proc p() = {.error: "msg".}``
          if it.kind in nkPragmaCallKinds: discard getStrLitNode(c, it)
          incl(sym.flags, sfError)
          excl(sym.flags, sfForward)
        else:
          let s = expectStrLit(c, it)
          recordPragma(c, it, "error", s)
          localError(c.config, it.info, errUser, s)
      of wFatal: fatal(c.config, it.info, errUser, expectStrLit(c, it))
      of wDefine: processDefine(c, it)
      of wUndef: processUndef(c, it)
      of wCompile: processCompile(c, it)
      of wLink: processLink(c, it)
      of wPassl:
        let s = expectStrLit(c, it)
        extccomp.addLinkOption(c.config, s)
        recordPragma(c, it, "passl", s)
      of wPassc:
        let s = expectStrLit(c, it)
        extccomp.addCompileOption(c.config, s)
        recordPragma(c, it, "passc", s)
      of wBreakpoint: pragmaBreakpoint(c, it)
      of wWatchPoint: pragmaWatchpoint(c, it)
      of wPush:
        processPush(c, n, i + 1)
        result = true
      of wPop: processPop(c, it)
      of wPragma:
        if not sym.isNil and sym.kind == skTemplate:
          sym.flags.incl sfCustomPragma
        else:
          processPragma(c, n, i)
          result = true
      of wDiscardable:
        noVal(c, it)
        if sym != nil: incl(sym.flags, sfDiscardable)
      of wNoInit:
        noVal(c, it)
        if sym != nil: incl(sym.flags, sfNoInit)
      of wCodegenDecl: processCodegenDecl(c, it, sym)
      of wChecks, wObjChecks, wFieldChecks, wRangechecks, wBoundchecks,
         wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints,
         wLinedir, wOptimization, wMovechecks, wCallconv, wDebugger, wProfiler,
         wFloatchecks, wNanChecks, wInfChecks, wPatterns, wTrMacros:
        processOption(c, it, c.config.options)
      of wStacktrace, wLinetrace:
        if sym.kind in {skProc, skMethod, skConverter}:
          processOption(c, it, sym.options)
        else:
          processOption(c, it, c.config.options)
      of FirstCallConv..LastCallConv:
        assert(sym != nil)
        if sym.typ == nil: invalidPragma(c, it)
        else: sym.typ.callConv = wordToCallConv(k)
      of wEmit: pragmaEmit(c, it)
      of wUnroll: pragmaUnroll(c, it)
      of wLinearScanEnd, wComputedGoto: noVal(c, it)
      of wEffects:
        # is later processed in effect analysis:
        noVal(c, it)
      of wIncompleteStruct:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfIncompleteStruct)
      of wUnchecked:
        noVal(c, it)
        if sym.typ == nil or sym.typ.kind notin {tyArray, tyUncheckedArray}:
          invalidPragma(c, it)
        else:
          sym.typ.kind = tyUncheckedArray
      of wUnion:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfUnion)
      of wRequiresInit:
        noVal(c, it)
        if sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfNeedsInit)
      of wByRef:
        noVal(c, it)
        if sym == nil or sym.typ == nil:
          processOption(c, it, c.config.options)
        else:
          incl(sym.typ.flags, tfByRef)
      of wByCopy:
        noVal(c, it)
        if sym.kind != skType or sym.typ == nil: invalidPragma(c, it)
        else: incl(sym.typ.flags, tfByCopy)
      of wPartial:
        noVal(c, it)
        if sym.kind != skType or sym.typ == nil: invalidPragma(c, it)
        else:
          incl(sym.typ.flags, tfPartial)
      of wInject, wGensym:
        # We check for errors, but do nothing with these pragmas otherwise
        # as they are handled directly in 'evalTemplate'.
        noVal(c, it)
        if sym == nil: invalidPragma(c, it)
      of wLine: pragmaLine(c, it)
      of wRaises, wTags: pragmaRaisesOrTags(c, it)
      of wLocks:
        if sym == nil: pragmaLockStmt(c, it)
        elif sym.typ == nil: invalidPragma(c, it)
        else: sym.typ.lockLevel = pragmaLocks(c, it)
      of wBitsize:
        if sym == nil or sym.kind != skField:
          invalidPragma(c, it)
        else:
          sym.bitsize = expectIntLit(c, it)
          if sym.bitsize <= 0:
            localError(c.config, it.info, "bitsize needs to be positive")
      of wGuard:
        if sym == nil or sym.kind notin {skVar, skLet, skField}:
          invalidPragma(c, it)
        else:
          sym.guard = pragmaGuard(c, it, sym.kind)
      of wGoto:
        if sym == nil or sym.kind notin {skVar, skLet}:
          invalidPragma(c, it)
        else:
          sym.flags.incl sfGoto
      of wCursor:
        if sym == nil or sym.kind notin {skVar, skLet}:
          invalidPragma(c, it)
        else:
          sym.flags.incl sfCursor
      of wExportNims:
        if sym == nil: invalidPragma(c, it)
        else: magicsys.registerNimScriptSymbol(c.graph, sym)
      of wInjectStmt:
        if it.kind notin nkPragmaCallKinds or it.len != 2:
          localError(c.config, it.info, "expression expected")
        else:
          it.sons[1] = c.semExpr(c, it.sons[1])
      of wExperimental:
        if not isTopLevel(c):
          localError(c.config, n.info, "'experimental' pragma only valid as toplevel statement or in a 'push' environment")
        processExperimental(c, it)
      of wThis:
        if it.kind in nkPragmaCallKinds and it.len == 2:
          c.selfName = considerQuotedIdent(c, it[1])
          message(c.config, n.info, warnDeprecated, "the '.this' pragma is deprecated")
        elif it.kind == nkIdent or it.len == 1:
          c.selfName = getIdent(c.cache, "self")
          message(c.config, n.info, warnDeprecated, "the '.this' pragma is deprecated")
        else:
          localError(c.config, it.info, "'this' pragma is allowed to have zero or one arguments")
      of wNoRewrite:
        noVal(c, it)
      of wBase:
        noVal(c, it)
        sym.flags.incl sfBase
      of wIntDefine:
        sym.magic = mIntDefine
      of wStrDefine:
        sym.magic = mStrDefine
      of wBoolDefine:
        sym.magic = mBoolDefine
      of wUsed:
        noVal(c, it)
        if sym == nil: invalidPragma(c, it)
        else: sym.flags.incl sfUsed
      of wLiftLocals: discard
      else: invalidPragma(c, it)
    elif comesFromPush and whichKeyword(ident) in {wTags, wRaises}:
      discard "ignore the .push pragma; it doesn't apply"
    else:
      if sym == nil or (sym != nil and sym.kind in {skVar, skLet, skParam,
                        skField, skProc, skFunc, skConverter, skMethod, skType}):
        n.sons[i] = semCustomPragma(c, it)
      elif sym != nil:
        illegalCustomPragma(c, it, sym)
      else:
        invalidPragma(c, it)

proc overwriteLineInfo(n: PNode; info: TLineInfo) =
  n.info = info
  for i in 0..<safeLen(n):
    overwriteLineInfo(n[i], info)

proc mergePragmas(n, pragmas: PNode) =
  var pragmas = copyTree(pragmas)
  overwriteLineInfo pragmas, n.info
  if n[pragmasPos].kind == nkEmpty:
    n[pragmasPos] = pragmas
  else:
    for p in pragmas: n.sons[pragmasPos].add p

proc implicitPragmas*(c: PContext, sym: PSym, n: PNode,
                      validPragmas: TSpecialWords) =
  if sym != nil and sym.kind != skModule:
    for it in c.optionStack:
      let o = it.otherPragmas
      if not o.isNil:
        pushInfoContext(c.config, n.info)
        var i = 0
        while i < o.len:
          if singlePragma(c, sym, o, i, validPragmas, true):
            internalError(c.config, n.info, "implicitPragmas")
          inc i
        popInfoContext(c.config)
        if sym.kind in routineKinds and sym.ast != nil: mergePragmas(sym.ast, o)

    if lfExportLib in sym.loc.flags and sfExportc notin sym.flags:
      localError(c.config, n.info, ".dynlib requires .exportc")
    var lib = c.optionStack[^1].dynlib
    if {lfDynamicLib, lfHeader} * sym.loc.flags == {} and
        sfImportc in sym.flags and lib != nil:
      incl(sym.loc.flags, lfDynamicLib)
      addToLib(lib, sym)
      if sym.loc.r == nil: sym.loc.r = rope(sym.name.s)

proc hasPragma*(n: PNode, pragma: TSpecialWord): bool =
  if n == nil: return false

  for p in n:
    var key = if p.kind in nkPragmaCallKinds and p.len > 1: p[0] else: p
    if key.kind == nkIdent and whichKeyword(key.ident) == pragma:
      return true

  return false

proc pragmaRec(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords) =
  if n == nil: return
  var i = 0
  while i < n.len:
    if singlePragma(c, sym, n, i, validPragmas, false): break
    inc i

proc pragma(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords) =
  if n == nil: return
  pragmaRec(c, sym, n, validPragmas)
  implicitPragmas(c, sym, n, validPragmas)
