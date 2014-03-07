#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements semantic checking for pragmas

import 
  os, platform, condsyms, ast, astalgo, idents, semdata, msgs, renderer, 
  wordrecg, ropes, options, strutils, lists, extccomp, math, magicsys, trees,
  rodread, types, lookups

const 
  FirstCallConv* = wNimcall
  LastCallConv* = wNoconv

const
  procPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wMagic, wNosideeffect, wSideeffect, wNoreturn, wDynlib, wHeader, 
    wCompilerproc, wProcVar, wDeprecated, wVarargs, wCompileTime, wMerge, 
    wBorrow, wExtern, wImportCompilerProc, wThread, wImportCpp, wImportObjC,
    wAsmNoStackFrame, wError, wDiscardable, wNoInit, wDestructor, wCodegenDecl,
    wGensym, wInject, wRaises, wTags, wOperator, wDelegator}
  converterPragmas* = procPragmas
  methodPragmas* = procPragmas
  templatePragmas* = {wImmediate, wDeprecated, wError, wGensym, wInject, wDirty,
    wDelegator}
  macroPragmas* = {FirstCallConv..LastCallConv, wImmediate, wImportc, wExportc,
    wNodecl, wMagic, wNosideeffect, wCompilerproc, wDeprecated, wExtern,
    wImportCpp, wImportObjC, wError, wDiscardable, wGensym, wInject, wDelegator}
  iteratorPragmas* = {FirstCallConv..LastCallConv, wNosideeffect, wSideeffect, 
    wImportc, wExportc, wNodecl, wMagic, wDeprecated, wBorrow, wExtern,
    wImportCpp, wImportObjC, wError, wDiscardable, wGensym, wInject, wRaises,
    wTags, wOperator}
  exprPragmas* = {wLine}
  stmtPragmas* = {wChecks, wObjChecks, wFieldChecks, wRangechecks,
    wBoundchecks, wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints,
    wLinedir, wStacktrace, wLinetrace, wOptimization, wHint, wWarning, wError,
    wFatal, wDefine, wUndef, wCompile, wLink, wLinksys, wPure, wPush, wPop,
    wBreakpoint, wWatchPoint, wPassl, wPassc, wDeadCodeElim, wDeprecated,
    wFloatchecks, wInfChecks, wNanChecks, wPragma, wEmit, wUnroll,
    wLinearScanEnd, wPatterns, wEffects, wNoForward, wComputedGoto,
    wInjectStmt}
  lambdaPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wNosideeffect, wSideeffect, wNoreturn, wDynlib, wHeader, 
    wDeprecated, wExtern, wThread, wImportCpp, wImportObjC, wAsmNoStackFrame,
    wRaises, wTags}
  typePragmas* = {wImportc, wExportc, wDeprecated, wMagic, wAcyclic, wNodecl, 
    wPure, wHeader, wCompilerproc, wFinal, wSize, wExtern, wShallow,
    wImportCpp, wImportObjC, wError, wIncompleteStruct, wByCopy, wByRef,
    wInheritable, wGensym, wInject, wRequiresInit, wUnchecked, wUnion}
  fieldPragmas* = {wImportc, wExportc, wDeprecated, wExtern, 
    wImportCpp, wImportObjC, wError}
  varPragmas* = {wImportc, wExportc, wVolatile, wRegister, wThreadVar, wNodecl, 
    wMagic, wHeader, wDeprecated, wCompilerproc, wDynlib, wExtern,
    wImportCpp, wImportObjC, wError, wNoInit, wCompileTime, wGlobal,
    wGensym, wInject, wCodegenDecl}
  constPragmas* = {wImportc, wExportc, wHeader, wDeprecated, wMagic, wNodecl,
    wExtern, wImportCpp, wImportObjC, wError, wGensym, wInject}
  letPragmas* = varPragmas
  procTypePragmas* = {FirstCallConv..LastCallConv, wVarargs, wNosideeffect,
                      wThread, wRaises, wTags}
  allRoutinePragmas* = procPragmas + iteratorPragmas + lambdaPragmas

proc pragma*(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords)
# implementation

proc invalidPragma(n: PNode) = 
  localError(n.info, errInvalidPragmaX, renderTree(n, {renderNoComments}))

proc pragmaAsm*(c: PContext, n: PNode): char = 
  result = '\0'
  if n != nil: 
    for i in countup(0, sonsLen(n) - 1): 
      let it = n.sons[i]
      if it.kind == nkExprColonExpr and it.sons[0].kind == nkIdent:
        case whichKeyword(it.sons[0].ident)
        of wSubsChar: 
          if it.sons[1].kind == nkCharLit: result = chr(int(it.sons[1].intVal))
          else: invalidPragma(it)
        else: invalidPragma(it)
      else: 
        invalidPragma(it)

proc setExternName(s: PSym, extname: string) =
  s.loc.r = toRope(extname % s.name.s)
  if gCmd == cmdPretty and '$' notin extname:
    # note that '{.importc.}' is transformed into '{.importc: "$1".}'
    s.loc.flags.incl(lfFullExternalName)

proc makeExternImport(s: PSym, extname: string) = 
  setExternName(s, extname)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)

proc validateExternCName(s: PSym, info: TLineInfo) =
  ## Validates that the symbol name in s.loc.r is a valid C identifier.
  ##
  ## Valid identifiers are those alphanumeric including the underscore not
  ## starting with a number. If the check fails, a generic error will be
  ## displayed to the user.
  let target = ropeToStr(s.loc.r)
  if target.len < 1 or target[0] notin IdentStartChars or
      not target.allCharsInSet(IdentChars):
    localError(info, errGenerated, "invalid exported symbol")

proc makeExternExport(s: PSym, extname: string, info: TLineInfo) =
  setExternName(s, extname)
  if gCmd in {cmdCompileToC, cmdCompileToCpp, cmdCompileToOC}:
    validateExternCName(s, info)
  incl(s.flags, sfExportc)

proc processImportCompilerProc(s: PSym, extname: string) =
  setExternName(s, extname)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)
  incl(s.loc.flags, lfImportCompilerProc)

proc processImportCpp(s: PSym, extname: string) =
  setExternName(s, extname)
  incl(s.flags, sfImportc)
  incl(s.flags, sfInfixCall)
  excl(s.flags, sfForward)

proc processImportObjC(s: PSym, extname: string) =
  setExternName(s, extname)
  incl(s.flags, sfImportc)
  incl(s.flags, sfNamedParamCall)
  excl(s.flags, sfForward)

proc newEmptyStrNode(n: PNode): PNode {.noinline.} =
  result = newNodeIT(nkStrLit, n.info, getSysType(tyString))
  result.strVal = ""

proc getStrLitNode(c: PContext, n: PNode): PNode =
  if n.kind != nkExprColonExpr: 
    localError(n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(n)
  else:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit: result = n.sons[1]
    else: 
      localError(n.info, errStringLiteralExpected)
      # error correction:
      result = newEmptyStrNode(n)

proc expectStrLit(c: PContext, n: PNode): string = 
  result = getStrLitNode(c, n).strVal

proc expectIntLit(c: PContext, n: PNode): int = 
  if n.kind != nkExprColonExpr: 
    localError(n.info, errIntLiteralExpected)
  else: 
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkIntLit..nkInt64Lit: result = int(n.sons[1].intVal)
    else: localError(n.info, errIntLiteralExpected)

proc getOptionalStr(c: PContext, n: PNode, defaultStr: string): string = 
  if n.kind == nkExprColonExpr: result = expectStrLit(c, n)
  else: result = defaultStr

proc processCodegenDecl(c: PContext, n: PNode, sym: PSym) =
  sym.constraint = getStrLitNode(c, n)

proc processMagic(c: PContext, n: PNode, s: PSym) = 
  #if sfSystemModule notin c.module.flags:
  #  liMessage(n.info, errMagicOnlyInSystem)
  if n.kind != nkExprColonExpr: 
    localError(n.info, errStringLiteralExpected)
    return
  var v: string
  if n.sons[1].kind == nkIdent: v = n.sons[1].ident.s
  else: v = expectStrLit(c, n)
  for m in countup(low(TMagic), high(TMagic)): 
    if substr($m, 1) == v: 
      s.magic = m
      break
  if s.magic == mNone: message(n.info, warnUnknownMagic, v)

proc wordToCallConv(sw: TSpecialWord): TCallingConvention = 
  # this assumes that the order of special words and calling conventions is
  # the same
  result = TCallingConvention(ord(ccDefault) + ord(sw) - ord(wNimcall))

proc isTurnedOn(c: PContext, n: PNode): bool = 
  if n.kind == nkExprColonExpr:
    let x = c.semConstBoolExpr(c, n.sons[1])
    n.sons[1] = x
    if x.kind == nkIntLit: return x.intVal != 0
  localError(n.info, errOnOrOffExpected)

proc onOff(c: PContext, n: PNode, op: TOptions) = 
  if isTurnedOn(c, n): gOptions = gOptions + op
  else: gOptions = gOptions - op
  
proc pragmaDeadCodeElim(c: PContext, n: PNode) = 
  if isTurnedOn(c, n): incl(c.module.flags, sfDeadCodeElim)
  else: excl(c.module.flags, sfDeadCodeElim)

proc pragmaNoForward(c: PContext, n: PNode) =
  if isTurnedOn(c, n): incl(c.module.flags, sfNoForward)
  else: excl(c.module.flags, sfNoForward)

proc processCallConv(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    var sw = whichKeyword(n.sons[1].ident)
    case sw
    of FirstCallConv..LastCallConv: 
      POptionEntry(c.optionStack.tail).defaultCC = wordToCallConv(sw)
    else: localError(n.info, errCallConvExpected)
  else: 
    localError(n.info, errCallConvExpected)
  
proc getLib(c: PContext, kind: TLibKind, path: PNode): PLib = 
  var it = PLib(c.libs.head)
  while it != nil: 
    if it.kind == kind: 
      if trees.exprStructuralEquivalent(it.path, path): return it
    it = PLib(it.next)
  result = newLib(kind)
  result.path = path
  append(c.libs, result)
  if path.kind in {nkStrLit..nkTripleStrLit}:
    result.isOverriden = options.isDynlibOverride(path.strVal)

proc expectDynlibNode(c: PContext, n: PNode): PNode =
  if n.kind != nkExprColonExpr:
    localError(n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(n)
  else:
    # For the OpenGL wrapper we support:
    # {.dynlib: myGetProcAddr(...).}
    result = c.semExpr(c, n.sons[1])
    if result.kind == nkSym and result.sym.kind == skConst:
      result = result.sym.ast # look it up
    if result.typ == nil or result.typ.kind notin {tyPointer, tyString, tyProc}:
      localError(n.info, errStringLiteralExpected)
      result = newEmptyStrNode(n)
    
proc processDynLib(c: PContext, n: PNode, sym: PSym) = 
  if (sym == nil) or (sym.kind == skModule):
    POptionEntry(c.optionStack.tail).dynlib = getLib(c, libDynamic, 
        expectDynlibNode(c, n))
  else:
    if n.kind == nkExprColonExpr:
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
  if (n.kind == nkExprColonExpr) and (sonsLen(n) == 2) and
      (n.sons[0].kind == nkBracketExpr) and
      (n.sons[0].sons[1].kind == nkIdent) and
      (n.sons[0].sons[0].kind == nkIdent) and (n.sons[1].kind == nkIdent):
    var nk: TNoteKind
    case whichKeyword(n.sons[0].sons[0].ident)
    of wHint:
      var x = findStr(msgs.HintsToStr, n.sons[0].sons[1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(hintMin))
      else: invalidPragma(n); return
    of wWarning:
      var x = findStr(msgs.WarningsToStr, n.sons[0].sons[1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(warnMin))
      else: invalidPragma(n); return
    else:
      invalidPragma(n)
      return

    let x = c.semConstBoolExpr(c, n.sons[1])
    n.sons[1] = x
    if x.kind == nkIntLit and x.intVal != 0: incl(gNotes, nk)
    else: excl(gNotes, nk)
  else: 
    invalidPragma(n)
  
proc processOption(c: PContext, n: PNode): bool = 
  if n.kind != nkExprColonExpr: result = true
  elif n.sons[0].kind == nkBracketExpr: processNote(c, n)
  elif n.sons[0].kind != nkIdent: result = true
  else:
    var sw = whichKeyword(n.sons[0].ident)
    case sw
    of wChecks: onOff(c, n, ChecksOptions)
    of wObjChecks: onOff(c, n, {optObjCheck})
    of wFieldChecks: onOff(c, n, {optFieldCheck})
    of wRangechecks: onOff(c, n, {optRangeCheck})
    of wBoundchecks: onOff(c, n, {optBoundsCheck})
    of wOverflowchecks: onOff(c, n, {optOverflowCheck})
    of wNilchecks: onOff(c, n, {optNilCheck})
    of wFloatchecks: onOff(c, n, {optNaNCheck, optInfCheck})
    of wNanChecks: onOff(c, n, {optNaNCheck})
    of wInfChecks: onOff(c, n, {optInfCheck})
    of wAssertions: onOff(c, n, {optAssert})
    of wWarnings: onOff(c, n, {optWarns})
    of wHints: onOff(c, n, {optHints})
    of wCallconv: processCallConv(c, n)   
    of wLinedir: onOff(c, n, {optLineDir})
    of wStacktrace: onOff(c, n, {optStackTrace})
    of wLinetrace: onOff(c, n, {optLineTrace})
    of wDebugger: onOff(c, n, {optEndb})
    of wProfiler: onOff(c, n, {optProfiler})
    of wByRef: onOff(c, n, {optByRef})
    of wDynlib: processDynLib(c, n, nil) 
    of wOptimization: 
      if n.sons[1].kind != nkIdent: 
        invalidPragma(n)
      else: 
        case n.sons[1].ident.s.normalize
        of "speed": 
          incl(gOptions, optOptimizeSpeed)
          excl(gOptions, optOptimizeSize)
        of "size":
          excl(gOptions, optOptimizeSpeed)
          incl(gOptions, optOptimizeSize)
        of "none": 
          excl(gOptions, optOptimizeSpeed)
          excl(gOptions, optOptimizeSize)
        else: localError(n.info, errNoneSpeedOrSizeExpected)
    of wImplicitStatic: onOff(c, n, {optImplicitStatic})
    of wPatterns: onOff(c, n, {optPatterns})
    else: result = true
  
proc processPush(c: PContext, n: PNode, start: int) = 
  if n.sons[start-1].kind == nkExprColonExpr:
    localError(n.info, errGenerated, "':' after 'push' not supported")
  var x = newOptionEntry()
  var y = POptionEntry(c.optionStack.tail)
  x.options = gOptions
  x.defaultCC = y.defaultCC
  x.dynlib = y.dynlib
  x.notes = gNotes
  append(c.optionStack, x)
  for i in countup(start, sonsLen(n) - 1): 
    if processOption(c, n.sons[i]):
      # simply store it somehwere:
      if x.otherPragmas.isNil:
        x.otherPragmas = newNodeI(nkPragma, n.info)
      x.otherPragmas.add n.sons[i]
    #LocalError(n.info, errOptionExpected)
  
proc processPop(c: PContext, n: PNode) = 
  if c.optionStack.counter <= 1: 
    localError(n.info, errAtPopWithoutPush)
  else: 
    gOptions = POptionEntry(c.optionStack.tail).options 
    gNotes = POptionEntry(c.optionStack.tail).notes
    remove(c.optionStack, c.optionStack.tail)

proc processDefine(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    defineSymbol(n.sons[1].ident.s)
    message(n.info, warnDeprecated, "define")
  else: 
    invalidPragma(n)
  
proc processUndef(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    undefSymbol(n.sons[1].ident.s)
    message(n.info, warnDeprecated, "undef")
  else: 
    invalidPragma(n)
  
type 
  TLinkFeature = enum 
    linkNormal, linkSys

proc processCompile(c: PContext, n: PNode) = 
  var s = expectStrLit(c, n)
  var found = findFile(s)
  if found == "": found = s
  var trunc = changeFileExt(found, "")
  extccomp.addExternalFileToCompile(found)
  extccomp.addFileToLink(completeCFilePath(trunc, false))

proc processCommonLink(c: PContext, n: PNode, feature: TLinkFeature) = 
  var f = expectStrLit(c, n)
  if splitFile(f).ext == "": f = addFileExt(f, CC[cCompiler].objExt)
  var found = findFile(f)
  if found == "": found = f # use the default
  case feature
  of linkNormal: extccomp.addFileToLink(found)
  of linkSys:
    extccomp.addFileToLink(libpath / completeCFilePath(found, false))
  else: internalError(n.info, "processCommonLink")
  
proc pragmaBreakpoint(c: PContext, n: PNode) = 
  discard getOptionalStr(c, n, "")

proc pragmaCheckpoint(c: PContext, n: PNode) = 
  # checkpoints can be used to debug the compiler; they are not documented
  var info = n.info
  inc(info.line)              # next line is affected!
  msgs.addCheckpoint(info)

proc pragmaWatchpoint(c: PContext, n: PNode) =
  if n.kind == nkExprColonExpr:
    n.sons[1] = c.semExpr(c, n.sons[1])
  else:
    invalidPragma(n)

proc semAsmOrEmit*(con: PContext, n: PNode, marker: char): PNode =
  case n.sons[1].kind
  of nkStrLit, nkRStrLit, nkTripleStrLit:
    result = newNode(if n.kind == nkAsmStmt: nkAsmStmt else: nkArgList, n.info)
    var str = n.sons[1].strVal
    if str == "":
      localError(n.info, errEmptyAsm)
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
        var e = searchInScopes(con, getIdent(sub))
        if e != nil: 
          if e.kind == skStub: loadStub(e)
          addSon(result, newSymNode(e))
        else: 
          addSon(result, newStrNode(nkStrLit, sub))
      if c < 0: break 
      a = c + 1
  else: illFormedAst(n)
  
proc pragmaEmit(c: PContext, n: PNode) = 
  discard getStrLitNode(c, n)
  n.sons[1] = semAsmOrEmit(c, n, '`')

proc noVal(n: PNode) = 
  if n.kind == nkExprColonExpr: invalidPragma(n)

proc pragmaUnroll(c: PContext, n: PNode) = 
  if c.p.nestedLoopCounter <= 0: 
    invalidPragma(n)
  elif n.kind == nkExprColonExpr:
    var unrollFactor = expectIntLit(c, n)
    if unrollFactor <% 32: 
      n.sons[1] = newIntNode(nkIntLit, unrollFactor)
    else: 
      invalidPragma(n)

proc pragmaLine(c: PContext, n: PNode) =
  if n.kind == nkExprColonExpr:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    let a = n.sons[1]
    if a.kind == nkPar: 
      var x = a.sons[0]
      var y = a.sons[1]
      if x.kind == nkExprColonExpr: x = x.sons[1]
      if y.kind == nkExprColonExpr: y = y.sons[1]
      if x.kind != nkStrLit: 
        localError(n.info, errStringLiteralExpected)
      elif y.kind != nkIntLit: 
        localError(n.info, errIntLiteralExpected)
      else:
        n.info.fileIndex = msgs.fileInfoIdx(x.strVal)
        n.info.line = int16(y.intVal)
    else:
      localError(n.info, errXExpected, "tuple")
  else:
    # sensible default:
    n.info = getInfoContext(-1)

proc processPragma(c: PContext, n: PNode, i: int) = 
  var it = n.sons[i]
  if it.kind != nkExprColonExpr: invalidPragma(n)
  elif it.sons[0].kind != nkIdent: invalidPragma(n)
  elif it.sons[1].kind != nkIdent: invalidPragma(n)
  
  var userPragma = newSym(skTemplate, it.sons[1].ident, nil, it.info)
  var body = newNodeI(nkPragma, n.info)
  for j in i+1 .. sonsLen(n)-1: addSon(body, n.sons[j])
  userPragma.ast = body
  strTableAdd(c.userPragmas, userPragma)

proc pragmaRaisesOrTags(c: PContext, n: PNode) =
  proc processExc(c: PContext, x: PNode) =
    var t = skipTypes(c.semTypeNode(c, x, nil), skipPtrs)
    if t.kind != tyObject:
      localError(x.info, errGenerated, "invalid type for raises/tags list")
    x.typ = t
    
  if n.kind == nkExprColonExpr:
    let it = n.sons[1]
    if it.kind notin {nkCurly, nkBracket}:
      processExc(c, it)
    else:
      for e in items(it): processExc(c, e)
  else:
    invalidPragma(n)

proc singlePragma(c: PContext, sym: PSym, n: PNode, i: int,
                  validPragmas: TSpecialWords): bool =
  var it = n.sons[i]
  var key = if it.kind == nkExprColonExpr: it.sons[0] else: it
  if key.kind == nkIdent: 
    var userPragma = strTableGet(c.userPragmas, key.ident)
    if userPragma != nil: 
      inc c.instCounter
      if c.instCounter > 100: 
        globalError(it.info, errRecursiveDependencyX, userPragma.name.s)
      pragma(c, sym, userPragma.ast, validPragmas)
      dec c.instCounter
    else:
      var k = whichKeyword(key.ident)
      if k in validPragmas: 
        case k
        of wExportc: 
          makeExternExport(sym, getOptionalStr(c, it, "$1"), it.info)
          incl(sym.flags, sfUsed) # avoid wrong hints
        of wImportc: makeExternImport(sym, getOptionalStr(c, it, "$1"))
        of wImportCompilerProc:
          processImportCompilerProc(sym, getOptionalStr(c, it, "$1"))
        of wExtern: setExternName(sym, expectStrLit(c, it))
        of wImmediate:
          if sym.kind in {skTemplate, skMacro}: incl(sym.flags, sfImmediate)
          else: invalidPragma(it)
        of wDirty:
          if sym.kind == skTemplate: incl(sym.flags, sfDirty)
          else: invalidPragma(it)
        of wImportCpp:
          processImportCpp(sym, getOptionalStr(c, it, "$1"))
        of wImportObjC:
          processImportObjC(sym, getOptionalStr(c, it, "$1"))
        of wAlign:
          if sym.typ == nil: invalidPragma(it)
          var align = expectIntLit(c, it)
          if not isPowerOfTwo(align) and align != 0: 
            localError(it.info, errPowerOfTwoExpected)
          else: 
            sym.typ.align = align              
        of wSize: 
          if sym.typ == nil: invalidPragma(it)
          var size = expectIntLit(c, it)
          if not isPowerOfTwo(size) or size <= 0 or size > 8: 
            localError(it.info, errPowerOfTwoExpected)
          else:
            sym.typ.size = size
        of wNodecl: 
          noVal(it)
          incl(sym.loc.flags, lfNoDecl)
        of wPure, wAsmNoStackFrame:
          noVal(it)
          if sym != nil:
            if k == wPure and sym.kind in routineKinds: invalidPragma(it)
            else: incl(sym.flags, sfPure)
        of wVolatile: 
          noVal(it)
          incl(sym.flags, sfVolatile)
        of wRegister: 
          noVal(it)
          incl(sym.flags, sfRegister)
        of wThreadVar: 
          noVal(it)
          incl(sym.flags, sfThread)
        of wDeadCodeElim: pragmaDeadCodeElim(c, it)
        of wNoForward: pragmaNoForward(c, it)
        of wMagic: processMagic(c, it, sym)
        of wCompileTime: 
          noVal(it)
          incl(sym.flags, sfCompileTime)
          incl(sym.loc.flags, lfNoDecl)
        of wGlobal:
          noVal(it)
          incl(sym.flags, sfGlobal)
          incl(sym.flags, sfPure)
        of wMerge: 
          noVal(it)
          incl(sym.flags, sfMerge)
        of wHeader: 
          var lib = getLib(c, libHeader, getStrLitNode(c, it))
          addToLib(lib, sym)
          incl(sym.flags, sfImportc)
          incl(sym.loc.flags, lfHeader)
          incl(sym.loc.flags, lfNoDecl) 
          # implies nodecl, because otherwise header would not make sense
          if sym.loc.r == nil: sym.loc.r = toRope(sym.name.s)
        of wDestructor:
          if sym.typ.sons.len == 2:
            sym.flags.incl sfDestructor
          else:
            invalidPragma(it)
        of wNosideeffect: 
          noVal(it)
          incl(sym.flags, sfNoSideEffect)
          if sym.typ != nil: incl(sym.typ.flags, tfNoSideEffect)
        of wSideeffect: 
          noVal(it)
          incl(sym.flags, sfSideEffect)
        of wNoreturn: 
          noVal(it)
          incl(sym.flags, sfNoReturn)
        of wDynlib: 
          processDynLib(c, it, sym)
        of wCompilerproc: 
          noVal(it)           # compilerproc may not get a string!
          makeExternExport(sym, "$1", it.info)
          incl(sym.flags, sfCompilerProc)
          incl(sym.flags, sfUsed) # suppress all those stupid warnings
          registerCompilerProc(sym)
        of wProcVar: 
          noVal(it)
          incl(sym.flags, sfProcvar)
        of wDeprecated: 
          noVal(it)
          if sym != nil: incl(sym.flags, sfDeprecated)
          else: incl(c.module.flags, sfDeprecated)
        of wVarargs: 
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfVarargs)
        of wBorrow: 
          noVal(it)
          incl(sym.flags, sfBorrow)
        of wFinal: 
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfFinal)
        of wInheritable:
          noVal(it)
          if sym.typ == nil or tfFinal in sym.typ.flags: invalidPragma(it)
          else: incl(sym.typ.flags, tfInheritable)
        of wAcyclic:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfAcyclic)
        of wShallow:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfShallow)
        of wThread:
          noVal(it)
          incl(sym.flags, sfThread)
          incl(sym.flags, sfProcvar)
          if sym.typ != nil: incl(sym.typ.flags, tfThread)
        of wHint: message(it.info, hintUser, expectStrLit(c, it))
        of wWarning: message(it.info, warnUser, expectStrLit(c, it))
        of wError: 
          if sym != nil and sym.isRoutine:
            # This is subtle but correct: the error *statement* is only
            # allowed for top level statements. Seems to be easier than 
            # distinguishing properly between
            # ``proc p() {.error}`` and ``proc p() = {.error: "msg".}``
            noVal(it)
            incl(sym.flags, sfError)
          else:
            localError(it.info, errUser, expectStrLit(c, it))
        of wFatal: fatal(it.info, errUser, expectStrLit(c, it))
        of wDefine: processDefine(c, it)
        of wUndef: processUndef(c, it)
        of wCompile: processCompile(c, it)
        of wLink: processCommonLink(c, it, linkNormal)
        of wLinksys: processCommonLink(c, it, linkSys)
        of wPassl: extccomp.addLinkOption(expectStrLit(c, it))
        of wPassc: extccomp.addCompileOption(expectStrLit(c, it))
        of wBreakpoint: pragmaBreakpoint(c, it)
        of wWatchPoint: pragmaWatchpoint(c, it)
        of wPush: 
          processPush(c, n, i + 1)
          result = true 
        of wPop: processPop(c, it)
        of wPragma: 
          processPragma(c, n, i)
          result = true
        of wDiscardable:
          noVal(it)
          if sym != nil: incl(sym.flags, sfDiscardable)
        of wNoInit:
          noVal(it)
          if sym != nil: incl(sym.flags, sfNoInit)
        of wCodegenDecl: processCodegenDecl(c, it, sym)
        of wChecks, wObjChecks, wFieldChecks, wRangechecks, wBoundchecks, 
           wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints, 
           wLinedir, wStacktrace, wLinetrace, wOptimization,
           wCallconv, 
           wDebugger, wProfiler, wFloatchecks, wNanChecks, wInfChecks,
           wPatterns:
          if processOption(c, it):
            # calling conventions (boring...):
            localError(it.info, errOptionExpected)
        of FirstCallConv..LastCallConv: 
          assert(sym != nil)
          if sym.typ == nil: invalidPragma(it)
          else: sym.typ.callConv = wordToCallConv(k)
        of wEmit: pragmaEmit(c, it)
        of wUnroll: pragmaUnroll(c, it)
        of wLinearScanEnd, wComputedGoto: noVal(it)
        of wEffects:
          # is later processed in effect analysis:
          noVal(it)
        of wIncompleteStruct:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfIncompleteStruct)
        of wUnchecked:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfUncheckedArray)
        of wUnion:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfUnion)
        of wRequiresInit:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfNeedsInit)
        of wByRef:
          noVal(it)
          if sym == nil or sym.typ == nil:
            if processOption(c, it): localError(it.info, errOptionExpected)
          else:
            incl(sym.typ.flags, tfByRef)
        of wByCopy:
          noVal(it)
          if sym.kind != skType or sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfByCopy)
        of wInject, wGensym:
          # We check for errors, but do nothing with these pragmas otherwise
          # as they are handled directly in 'evalTemplate'.
          noVal(it)
          if sym == nil: invalidPragma(it)
        of wLine: pragmaLine(c, it)
        of wRaises, wTags: pragmaRaisesOrTags(c, it)
        of wOperator:
          if sym == nil: invalidPragma(it)
          else: sym.position = expectIntLit(c, it)
        of wInjectStmt:
          if it.kind != nkExprColonExpr:
            localError(it.info, errExprExpected)
          else: 
            it.sons[1] = c.semExpr(c, it.sons[1])
        else: invalidPragma(it)
      else: invalidPragma(it)
  else: processNote(c, it)

proc implictPragmas*(c: PContext, sym: PSym, n: PNode,
                     validPragmas: TSpecialWords) =
  if sym != nil and sym.kind != skModule:
    var it = POptionEntry(c.optionStack.head)
    while it != nil:
      let o = it.otherPragmas
      if not o.isNil:
        for i in countup(0, sonsLen(o) - 1):
          if singlePragma(c, sym, o, i, validPragmas):
            internalError(n.info, "implicitPragmas")
      it = it.next.POptionEntry

    if lfExportLib in sym.loc.flags and sfExportc notin sym.flags: 
      localError(n.info, errDynlibRequiresExportc)
    var lib = POptionEntry(c.optionStack.tail).dynlib
    if {lfDynamicLib, lfHeader} * sym.loc.flags == {} and
        sfImportc in sym.flags and lib != nil:
      incl(sym.loc.flags, lfDynamicLib)
      addToLib(lib, sym)
      if sym.loc.r == nil: sym.loc.r = toRope(sym.name.s)

proc hasPragma*(n: PNode, pragma: TSpecialWord): bool =
  if n == nil or n.sons == nil:
    return false

  for p in n.sons:
    var key = if p.kind == nkExprColonExpr: p[0] else: p
    if key.kind == nkIdent and whichKeyword(key.ident) == pragma:
      return true
  
  return false

proc pragma(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords) =
  if n == nil: return
  for i in countup(0, sonsLen(n) - 1):
    if singlePragma(c, sym, n, i, validPragmas): break
  implictPragmas(c, sym, n, validPragmas)
