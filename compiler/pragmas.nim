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
    wMagic, wNosideEffect, wSideEffect, wNoreturn, wDynLib, wHeader, 
    wCompilerProc, wProcVar, wDeprecated, wVarargs, wCompileTime, wMerge, 
    wBorrow, wExtern, wImportCompilerProc, wThread, wImportCpp, wImportObjC,
    wNoStackFrame, wError, wDiscardable, wNoInit, wDestructor, wCodegenDecl,
    wGenSym, wInject, wRaises, wTags, wOperator, wDelegator}
  converterPragmas* = procPragmas
  methodPragmas* = procPragmas
  templatePragmas* = {wImmediate, wDeprecated, wError, wGenSym, wInject, wDirty,
    wDelegator}
  macroPragmas* = {FirstCallConv..LastCallConv, wImmediate, wImportc, wExportc,
    wNodecl, wMagic, wNosideEffect, wCompilerProc, wDeprecated, wExtern,
    wImportcpp, wImportobjc, wError, wDiscardable, wGenSym, wInject, wDelegator}
  iteratorPragmas* = {FirstCallConv..LastCallConv, wNosideEffect, wSideEffect, 
    wImportc, wExportc, wNodecl, wMagic, wDeprecated, wBorrow, wExtern,
    wImportcpp, wImportobjc, wError, wDiscardable, wGenSym, wInject, wRaises,
    wTags, wOperator}
  exprPragmas* = {wLine}
  stmtPragmas* = {wChecks, wObjChecks, wFieldChecks, wRangechecks,
    wBoundchecks, wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints,
    wLinedir, wStacktrace, wLinetrace, wOptimization, wHint, wWarning, wError,
    wFatal, wDefine, wUndef, wCompile, wLink, wLinkSys, wPure, wPush, wPop,
    wBreakpoint, wWatchpoint, wPassL, wPassC, wDeadCodeElim, wDeprecated,
    wFloatChecks, wInfChecks, wNanChecks, wPragma, wEmit, wUnroll,
    wLinearScanEnd, wPatterns, wEffects, wNoForward, wComputedGoto,
    wInjectStmt}
  lambdaPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wNosideEffect, wSideEffect, wNoreturn, wDynLib, wHeader, 
    wDeprecated, wExtern, wThread, wImportcpp, wImportobjc, wNoStackFrame,
    wRaises, wTags}
  typePragmas* = {wImportc, wExportc, wDeprecated, wMagic, wAcyclic, wNodecl, 
    wPure, wHeader, wCompilerProc, wFinal, wSize, wExtern, wShallow, 
    wImportcpp, wImportobjc, wError, wIncompleteStruct, wByCopy, wByRef,
    wInheritable, wGenSym, wInject, wRequiresInit}
  fieldPragmas* = {wImportc, wExportc, wDeprecated, wExtern, 
    wImportcpp, wImportobjc, wError}
  varPragmas* = {wImportc, wExportc, wVolatile, wRegister, wThreadVar, wNodecl, 
    wMagic, wHeader, wDeprecated, wCompilerProc, wDynLib, wExtern,
    wImportcpp, wImportobjc, wError, wNoInit, wCompileTime, wGlobal,
    wGenSym, wInject, wCodegenDecl}
  constPragmas* = {wImportc, wExportc, wHeader, wDeprecated, wMagic, wNodecl,
    wExtern, wImportcpp, wImportobjc, wError, wGenSym, wInject}
  letPragmas* = varPragmas
  procTypePragmas* = {FirstCallConv..LastCallConv, wVarargs, wNosideEffect,
                      wThread, wRaises, wTags}
  allRoutinePragmas* = procPragmas + iteratorPragmas + lambdaPragmas

proc pragma*(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords)
# implementation

proc invalidPragma(n: PNode) = 
  LocalError(n.info, errInvalidPragmaX, renderTree(n, {renderNoComments}))

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

proc MakeExternImport(s: PSym, extname: string) = 
  setExternName(s, extname)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)

proc MakeExternExport(s: PSym, extname: string) = 
  setExternName(s, extname)
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
    LocalError(n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(n)
  else:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit: result = n.sons[1]
    else: 
      LocalError(n.info, errStringLiteralExpected)
      # error correction:
      result = newEmptyStrNode(n)

proc expectStrLit(c: PContext, n: PNode): string = 
  result = getStrLitNode(c, n).strVal

proc expectIntLit(c: PContext, n: PNode): int = 
  if n.kind != nkExprColonExpr: 
    LocalError(n.info, errIntLiteralExpected)
  else: 
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkIntLit..nkInt64Lit: result = int(n.sons[1].intVal)
    else: LocalError(n.info, errIntLiteralExpected)

proc getOptionalStr(c: PContext, n: PNode, defaultStr: string): string = 
  if n.kind == nkExprColonExpr: result = expectStrLit(c, n)
  else: result = defaultStr

proc processCodegenDecl(c: PContext, n: PNode, sym: PSym) =
  sym.constraint = getStrLitNode(c, n)

proc processMagic(c: PContext, n: PNode, s: PSym) = 
  #if sfSystemModule notin c.module.flags:
  #  liMessage(n.info, errMagicOnlyInSystem)
  if n.kind != nkExprColonExpr: 
    LocalError(n.info, errStringLiteralExpected)
    return
  var v: string
  if n.sons[1].kind == nkIdent: v = n.sons[1].ident.s
  else: v = expectStrLit(c, n)
  for m in countup(low(TMagic), high(TMagic)): 
    if substr($m, 1) == v: 
      s.magic = m
      break
  if s.magic == mNone: Message(n.info, warnUnknownMagic, v)

proc wordToCallConv(sw: TSpecialWord): TCallingConvention = 
  # this assumes that the order of special words and calling conventions is
  # the same
  result = TCallingConvention(ord(ccDefault) + ord(sw) - ord(wNimcall))

proc IsTurnedOn(c: PContext, n: PNode): bool = 
  if n.kind == nkExprColonExpr:
    let x = c.semConstBoolExpr(c, n.sons[1])
    n.sons[1] = x
    if x.kind == nkIntLit: return x.intVal != 0
  LocalError(n.info, errOnOrOffExpected)

proc onOff(c: PContext, n: PNode, op: TOptions) = 
  if IsTurnedOn(c, n): gOptions = gOptions + op
  else: gOptions = gOptions - op
  
proc pragmaDeadCodeElim(c: PContext, n: PNode) = 
  if IsTurnedOn(c, n): incl(c.module.flags, sfDeadCodeElim)
  else: excl(c.module.flags, sfDeadCodeElim)

proc pragmaNoForward(c: PContext, n: PNode) =
  if IsTurnedOn(c, n): incl(c.module.flags, sfNoForward)
  else: excl(c.module.flags, sfNoForward)

proc processCallConv(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    var sw = whichKeyword(n.sons[1].ident)
    case sw
    of firstCallConv..lastCallConv: 
      POptionEntry(c.optionStack.tail).defaultCC = wordToCallConv(sw)
    else: LocalError(n.info, errCallConvExpected)
  else: 
    LocalError(n.info, errCallConvExpected)
  
proc getLib(c: PContext, kind: TLibKind, path: PNode): PLib = 
  var it = PLib(c.libs.head)
  while it != nil: 
    if it.kind == kind: 
      if trees.ExprStructuralEquivalent(it.path, path): return it
    it = PLib(it.next)
  result = newLib(kind)
  result.path = path
  Append(c.libs, result)
  if path.kind in {nkStrLit..nkTripleStrLit}:
    result.isOverriden = options.isDynLibOverride(path.strVal)

proc expectDynlibNode(c: PContext, n: PNode): PNode =
  if n.kind != nkExprColonExpr:
    LocalError(n.info, errStringLiteralExpected)
    # error correction:
    result = newEmptyStrNode(n)
  else:
    # For the OpenGL wrapper we support:
    # {.dynlib: myGetProcAddr(...).}
    result = c.semExpr(c, n.sons[1])
    if result.kind == nkSym and result.sym.kind == skConst:
      result = result.sym.ast # look it up
    if result.typ == nil or result.typ.kind notin {tyPointer, tyString, tyProc}:
      LocalError(n.info, errStringLiteralExpected)
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
    if sym.kind in RoutineKinds and sym.typ != nil and 
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
      else: InvalidPragma(n); return
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
    of wChecks: OnOff(c, n, checksOptions)
    of wObjChecks: OnOff(c, n, {optObjCheck})
    of wFieldchecks: OnOff(c, n, {optFieldCheck})
    of wRangechecks: OnOff(c, n, {optRangeCheck})
    of wBoundchecks: OnOff(c, n, {optBoundsCheck})
    of wOverflowchecks: OnOff(c, n, {optOverflowCheck})
    of wNilchecks: OnOff(c, n, {optNilCheck})
    of wFloatChecks: OnOff(c, n, {optNanCheck, optInfCheck})
    of wNaNchecks: OnOff(c, n, {optNanCheck})
    of wInfChecks: OnOff(c, n, {optInfCheck})
    of wAssertions: OnOff(c, n, {optAssert})
    of wWarnings: OnOff(c, n, {optWarns})
    of wHints: OnOff(c, n, {optHints})
    of wCallConv: processCallConv(c, n)   
    of wLinedir: OnOff(c, n, {optLineDir})
    of wStacktrace: OnOff(c, n, {optStackTrace})
    of wLinetrace: OnOff(c, n, {optLineTrace})
    of wDebugger: OnOff(c, n, {optEndb})
    of wProfiler: OnOff(c, n, {optProfiler})
    of wByRef: OnOff(c, n, {optByRef})
    of wDynLib: processDynLib(c, n, nil) 
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
        else: LocalError(n.info, errNoneSpeedOrSizeExpected)
    of wImplicitStatic: OnOff(c, n, {optImplicitStatic})
    of wPatterns: OnOff(c, n, {optPatterns})
    else: result = true
  
proc processPush(c: PContext, n: PNode, start: int) = 
  if n.sons[start-1].kind == nkExprColonExpr:
    LocalError(n.info, errGenerated, "':' after 'push' not supported")
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
    LocalError(n.info, errAtPopWithoutPush)
  else: 
    gOptions = POptionEntry(c.optionStack.tail).options 
    gNotes = POptionEntry(c.optionStack.tail).notes
    remove(c.optionStack, c.optionStack.tail)

proc processDefine(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    DefineSymbol(n.sons[1].ident.s)
    Message(n.info, warnDeprecated, "define")
  else: 
    invalidPragma(n)
  
proc processUndef(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    UndefSymbol(n.sons[1].ident.s)
    Message(n.info, warnDeprecated, "undef")
  else: 
    invalidPragma(n)
  
type 
  TLinkFeature = enum 
    linkNormal, linkSys

proc processCompile(c: PContext, n: PNode) = 
  var s = expectStrLit(c, n)
  var found = findFile(s)
  if found == "": found = s
  var trunc = ChangeFileExt(found, "")
  extccomp.addExternalFileToCompile(found)
  extccomp.addFileToLink(completeCFilePath(trunc, false))

proc processCommonLink(c: PContext, n: PNode, feature: TLinkFeature) = 
  var f = expectStrLit(c, n)
  if splitFile(f).ext == "": f = addFileExt(f, cc[ccompiler].objExt)
  var found = findFile(f)
  if found == "": found = f # use the default
  case feature
  of linkNormal: extccomp.addFileToLink(found)
  of linkSys:
    extccomp.addFileToLink(libpath / completeCFilePath(found, false))
  else: internalError(n.info, "processCommonLink")
  
proc PragmaBreakpoint(c: PContext, n: PNode) = 
  discard getOptionalStr(c, n, "")

proc PragmaCheckpoint(c: PContext, n: PNode) = 
  # checkpoints can be used to debug the compiler; they are not documented
  var info = n.info
  inc(info.line)              # next line is affected!
  msgs.addCheckpoint(info)

proc PragmaWatchpoint(c: PContext, n: PNode) =
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
      LocalError(n.info, errEmptyAsm)
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
  
proc PragmaEmit(c: PContext, n: PNode) = 
  discard getStrLitNode(c, n)
  n.sons[1] = semAsmOrEmit(c, n, '`')

proc noVal(n: PNode) = 
  if n.kind == nkExprColonExpr: invalidPragma(n)

proc PragmaUnroll(c: PContext, n: PNode) = 
  if c.p.nestedLoopCounter <= 0: 
    invalidPragma(n)
  elif n.kind == nkExprColonExpr:
    var unrollFactor = expectIntLit(c, n)
    if unrollFactor <% 32: 
      n.sons[1] = newIntNode(nkIntLit, unrollFactor)
    else: 
      invalidPragma(n)

proc PragmaLine(c: PContext, n: PNode) =
  if n.kind == nkExprColonExpr:
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    let a = n.sons[1]
    if a.kind == nkPar: 
      var x = a.sons[0]
      var y = a.sons[1]
      if x.kind == nkExprColonExpr: x = x.sons[1]
      if y.kind == nkExprColonExpr: y = y.sons[1]
      if x.kind != nkStrLit: 
        LocalError(n.info, errStringLiteralExpected)
      elif y.kind != nkIntLit: 
        LocalError(n.info, errIntLiteralExpected)
      else:
        n.info.fileIndex = msgs.fileInfoIdx(x.strVal)
        n.info.line = int16(y.intVal)
    else:
      LocalError(n.info, errXExpected, "tuple")
  else:
    # sensible default:
    n.info = getInfoContext(-1)

proc processPragma(c: PContext, n: PNode, i: int) = 
  var it = n.sons[i]
  if it.kind != nkExprColonExpr: invalidPragma(n)
  elif it.sons[0].kind != nkIdent: invalidPragma(n)
  elif it.sons[1].kind != nkIdent: invalidPragma(n)
  
  var userPragma = NewSym(skTemplate, it.sons[1].ident, nil, it.info)
  var body = newNodeI(nkPragma, n.info)
  for j in i+1 .. sonsLen(n)-1: addSon(body, n.sons[j])
  userPragma.ast = body
  StrTableAdd(c.userPragmas, userPragma)

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
    var userPragma = StrTableGet(c.userPragmas, key.ident)
    if userPragma != nil: 
      inc c.InstCounter
      if c.InstCounter > 100: 
        GlobalError(it.info, errRecursiveDependencyX, userPragma.name.s)
      pragma(c, sym, userPragma.ast, validPragmas)
      dec c.InstCounter
    else:
      var k = whichKeyword(key.ident)
      if k in validPragmas: 
        case k
        of wExportc: 
          makeExternExport(sym, getOptionalStr(c, it, "$1"))
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
          if not IsPowerOfTwo(align) and align != 0: 
            LocalError(it.info, errPowerOfTwoExpected)
          else: 
            sym.typ.align = align              
        of wSize: 
          if sym.typ == nil: invalidPragma(it)
          var size = expectIntLit(c, it)
          if not IsPowerOfTwo(size) or size <= 0 or size > 8: 
            LocalError(it.info, errPowerOfTwoExpected)
          else:
            sym.typ.size = size
        of wNodecl: 
          noVal(it)
          incl(sym.loc.Flags, lfNoDecl)
        of wPure, wNoStackFrame:
          noVal(it)
          if sym != nil: incl(sym.flags, sfPure)
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
          incl(sym.loc.Flags, lfNoDecl)
        of wGlobal:
          noVal(it)
          incl(sym.flags, sfGlobal)
          incl(sym.flags, sfPure)
        of wMerge: 
          noval(it)
          incl(sym.flags, sfMerge)
        of wHeader: 
          var lib = getLib(c, libHeader, getStrLitNode(c, it))
          addToLib(lib, sym)
          incl(sym.flags, sfImportc)
          incl(sym.loc.flags, lfHeader)
          incl(sym.loc.Flags, lfNoDecl) 
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
        of wSideEffect: 
          noVal(it)
          incl(sym.flags, sfSideEffect)
        of wNoReturn: 
          noVal(it)
          incl(sym.flags, sfNoReturn)
        of wDynLib: 
          processDynLib(c, it, sym)
        of wCompilerProc: 
          noVal(it)           # compilerproc may not get a string!
          makeExternExport(sym, "$1")
          incl(sym.flags, sfCompilerProc)
          incl(sym.flags, sfUsed) # suppress all those stupid warnings
          registerCompilerProc(sym)
        of wProcvar: 
          noVal(it)
          incl(sym.flags, sfProcVar)
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
          incl(sym.flags, sfProcVar)
          if sym.typ != nil: incl(sym.typ.flags, tfThread)
        of wHint: Message(it.info, hintUser, expectStrLit(c, it))
        of wWarning: Message(it.info, warnUser, expectStrLit(c, it))
        of wError: 
          if sym != nil and sym.isRoutine:
            # This is subtle but correct: the error *statement* is only
            # allowed for top level statements. Seems to be easier than 
            # distinguishing properly between
            # ``proc p() {.error}`` and ``proc p() = {.error: "msg".}``
            noVal(it)
            incl(sym.flags, sfError)
          else:
            LocalError(it.info, errUser, expectStrLit(c, it))
        of wFatal: Fatal(it.info, errUser, expectStrLit(c, it))
        of wDefine: processDefine(c, it)
        of wUndef: processUndef(c, it)
        of wCompile: processCompile(c, it)
        of wLink: processCommonLink(c, it, linkNormal)
        of wLinkSys: processCommonLink(c, it, linkSys)
        of wPassL: extccomp.addLinkOption(expectStrLit(c, it))
        of wPassC: extccomp.addCompileOption(expectStrLit(c, it))
        of wBreakpoint: PragmaBreakpoint(c, it)
        of wWatchpoint: PragmaWatchpoint(c, it)
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
           wCallConv, 
           wDebugger, wProfiler, wFloatChecks, wNanChecks, wInfChecks,
           wPatterns:
          if processOption(c, it):
            # calling conventions (boring...):
            LocalError(it.info, errOptionExpected)
        of firstCallConv..lastCallConv: 
          assert(sym != nil)
          if sym.typ == nil: invalidPragma(it)
          else: sym.typ.callConv = wordToCallConv(k)
        of wEmit: PragmaEmit(c, it)
        of wUnroll: PragmaUnroll(c, it)
        of wLinearScanEnd, wComputedGoto: noVal(it)
        of wEffects:
          # is later processed in effect analysis:
          noVal(it)
        of wIncompleteStruct:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfIncompleteStruct)
        of wRequiresInit:
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfNeedsInit)
        of wByRef:
          noVal(it)
          if sym == nil or sym.typ == nil:
            if processOption(c, it): LocalError(it.info, errOptionExpected)
          else:
            incl(sym.typ.flags, tfByRef)
        of wByCopy:
          noVal(it)
          if sym.kind != skType or sym.typ == nil: invalidPragma(it)
          else: incl(sym.typ.flags, tfByCopy)
        of wInject, wGenSym:
          # We check for errors, but do nothing with these pragmas otherwise
          # as they are handled directly in 'evalTemplate'.
          noVal(it)
          if sym == nil: invalidPragma(it)
        of wLine: PragmaLine(c, it)
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
    var it = POptionEntry(c.optionstack.head)
    while it != nil:
      let o = it.otherPragmas
      if not o.isNil:
        for i in countup(0, sonsLen(o) - 1):
          if singlePragma(c, sym, o, i, validPragmas):
            InternalError(n.info, "implicitPragmas")
      it = it.next.POptionEntry

    if lfExportLib in sym.loc.flags and sfExportc notin sym.flags: 
      LocalError(n.info, errDynlibRequiresExportc)
    var lib = POptionEntry(c.optionstack.tail).dynlib
    if {lfDynamicLib, lfHeader} * sym.loc.flags == {} and
        sfImportc in sym.flags and lib != nil:
      incl(sym.loc.flags, lfDynamicLib)
      addToLib(lib, sym)
      if sym.loc.r == nil: sym.loc.r = toRope(sym.name.s)

proc pragma(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords) =
  if n == nil: return
  for i in countup(0, sonsLen(n) - 1):
    if singlePragma(c, sym, n, i, validPragmas): break
  implictPragmas(c, sym, n, validPragmas)
