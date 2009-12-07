#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements semantic checking for pragmas

import 
  os, platform, condsyms, ast, astalgo, idents, semdata, msgs, rnimsyn, 
  wordrecg, ropes, options, strutils, lists, extccomp, math, magicsys

const 
  FirstCallConv* = wNimcall
  LastCallConv* = wNoconv

const 
  procPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wMagic, wNosideEffect, wSideEffect, wNoreturn, wDynLib, wHeader, 
    wCompilerProc, wPure, wProcVar, wDeprecated, wVarargs, wCompileTime, wMerge, 
    wBorrow}
  converterPragmas* = procPragmas
  methodPragmas* = procPragmas
  macroPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wMagic, wNosideEffect, wCompilerProc, wDeprecated, wTypeCheck}
  iteratorPragmas* = {FirstCallConv..LastCallConv, wNosideEffect, wSideEffect, 
    wImportc, wExportc, wNodecl, wMagic, wDeprecated, wBorrow}
  stmtPragmas* = {wChecks, wObjChecks, wFieldChecks, wRangechecks, wBoundchecks, 
    wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints, wLinedir, 
    wStacktrace, wLinetrace, wOptimization, wHint, wWarning, wError, wFatal, 
    wDefine, wUndef, wCompile, wLink, wLinkSys, wPure, wPush, wPop, wBreakpoint, 
    wCheckpoint, wPassL, wPassC, wDeadCodeElim, wDeprecated}
  lambdaPragmas* = {FirstCallConv..LastCallConv, wImportc, wExportc, wNodecl, 
    wNosideEffect, wSideEffect, wNoreturn, wDynLib, wHeader, wPure, wDeprecated}
  typePragmas* = {wImportc, wExportc, wDeprecated, wMagic, wAcyclic, wNodecl, 
    wPure, wHeader, wCompilerProc, wFinal}
  fieldPragmas* = {wImportc, wExportc, wDeprecated}
  varPragmas* = {wImportc, wExportc, wVolatile, wRegister, wThreadVar, wNodecl, 
    wMagic, wHeader, wDeprecated, wCompilerProc, wDynLib}
  constPragmas* = {wImportc, wExportc, wHeader, wDeprecated, wMagic, wNodecl}
  procTypePragmas* = {FirstCallConv..LastCallConv, wVarargs, wNosideEffect}

proc pragma*(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords)
proc pragmaAsm*(c: PContext, n: PNode): char
# implementation

proc invalidPragma(n: PNode) = 
  liMessage(n.info, errInvalidPragmaX, renderTree(n, {renderNoComments}))

proc pragmaAsm(c: PContext, n: PNode): char = 
  var it: PNode
  result = '\0'
  if n != nil: 
    for i in countup(0, sonsLen(n) - 1): 
      it = n.sons[i]
      if (it.kind == nkExprColonExpr) and (it.sons[0].kind == nkIdent): 
        case whichKeyword(it.sons[0].ident)
        of wSubsChar: 
          if it.sons[1].kind == nkCharLit: result = chr(int(it.sons[1].intVal))
          else: invalidPragma(it)
        else: invalidPragma(it)
      else: 
        invalidPragma(it)
  
const 
  FirstPragmaWord = wMagic
  LastPragmaWord = wNoconv

proc MakeExternImport(s: PSym, extname: string) = 
  s.loc.r = toRope(extname)
  incl(s.flags, sfImportc)
  excl(s.flags, sfForward)

proc MakeExternExport(s: PSym, extname: string) = 
  s.loc.r = toRope(extname)
  incl(s.flags, sfExportc)

proc expectStrLit(c: PContext, n: PNode): string = 
  if n.kind != nkExprColonExpr: 
    liMessage(n.info, errStringLiteralExpected)
    result = ""
  else: 
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkStrLit, nkRStrLit, nkTripleStrLit: result = n.sons[1].strVal
    else: 
      liMessage(n.info, errStringLiteralExpected)
      result = ""

proc expectIntLit(c: PContext, n: PNode): int = 
  if n.kind != nkExprColonExpr: 
    liMessage(n.info, errIntLiteralExpected)
    result = 0
  else: 
    n.sons[1] = c.semConstExpr(c, n.sons[1])
    case n.sons[1].kind
    of nkIntLit..nkInt64Lit: result = int(n.sons[1].intVal)
    else: 
      liMessage(n.info, errIntLiteralExpected)
      result = 0

proc getOptionalStr(c: PContext, n: PNode, defaultStr: string): string = 
  if n.kind == nkExprColonExpr: result = expectStrLit(c, n)
  else: result = defaultStr
  
proc processMagic(c: PContext, n: PNode, s: PSym) = 
  var v: string
  #if not (sfSystemModule in c.module.flags) then
  #  liMessage(n.info, errMagicOnlyInSystem);
  if n.kind != nkExprColonExpr: liMessage(n.info, errStringLiteralExpected)
  if n.sons[1].kind == nkIdent: v = n.sons[1].ident.s
  else: v = expectStrLit(c, n)
  incl(s.flags, sfImportc) # magics don't need an implementation, so we
                           # treat them as imported, instead of modifing a lot of working code
                           # BUGFIX: magic does not imply ``lfNoDecl`` anymore!
  for m in countup(low(TMagic), high(TMagic)): 
    if magicToStr[m] == v: 
      s.magic = m
      return 
  liMessage(n.info, warnUnknownMagic, v)

proc wordToCallConv(sw: TSpecialWord): TCallingConvention = 
  # this assumes that the order of special words and calling conventions is
  # the same
  result = TCallingConvention(ord(ccDefault) + ord(sw) - ord(wNimcall))

proc onOff(c: PContext, n: PNode, op: TOptions) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    case whichKeyword(n.sons[1].ident)
    of wOn: gOptions = gOptions + op
    of wOff: gOptions = gOptions - op
    else: liMessage(n.info, errOnOrOffExpected)
  else: 
    liMessage(n.info, errOnOrOffExpected)
  
proc pragmaDeadCodeElim(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    case whichKeyword(n.sons[1].ident)
    of wOn: incl(c.module.flags, sfDeadCodeElim)
    of wOff: excl(c.module.flags, sfDeadCodeElim)
    else: liMessage(n.info, errOnOrOffExpected)
  else: 
    liMessage(n.info, errOnOrOffExpected)
  
proc processCallConv(c: PContext, n: PNode) = 
  var sw: TSpecialWord
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    sw = whichKeyword(n.sons[1].ident)
    case sw
    of firstCallConv..lastCallConv: 
      POptionEntry(c.optionStack.tail).defaultCC = wordToCallConv(sw)
    else: liMessage(n.info, errCallConvExpected)
  else: 
    liMessage(n.info, errCallConvExpected)
  
proc getLib(c: PContext, kind: TLibKind, path: string): PLib = 
  var it: PLib
  it = PLib(c.libs.head)
  while it != nil: 
    if it.kind == kind: 
      if ospCaseInsensitive in platform.OS[targetOS].props: 
        if cmpIgnoreCase(it.path, path) == 0: 
          return it
      else: 
        if it.path == path: 
          return it
    it = PLib(it.next)
  result = newLib(kind)
  result.path = path
  Append(c.libs, result)

proc processDynLib(c: PContext, n: PNode, sym: PSym) = 
  var lib: PLib
  if (sym == nil) or (sym.kind == skModule): 
    POptionEntry(c.optionStack.tail).dynlib = getLib(c, libDynamic, 
        expectStrLit(c, n))
  elif n.kind == nkExprColonExpr: 
    lib = getLib(c, libDynamic, expectStrLit(c, n))
    addToLib(lib, sym)
    incl(sym.loc.flags, lfDynamicLib)
  else: 
    incl(sym.loc.flags, lfExportLib)
  
proc processNote(c: PContext, n: PNode) = 
  var 
    x: int
    nk: TNoteKind
  if (n.kind == nkExprColonExpr) and (sonsLen(n) == 2) and
      (n.sons[0].kind == nkBracketExpr) and
      (n.sons[0].sons[1].kind == nkIdent) and
      (n.sons[0].sons[0].kind == nkIdent) and (n.sons[1].kind == nkIdent): 
    case whichKeyword(n.sons[0].sons[0].ident)
    of wHint: 
      x = findStr(msgs.HintsToStr, n.sons[0].sons[1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(hintMin))
      else: invalidPragma(n)
    of wWarning: 
      x = findStr(msgs.WarningsToStr, n.sons[0].sons[1].ident.s)
      if x >= 0: nk = TNoteKind(x + ord(warnMin))
      else: InvalidPragma(n)
    else: 
      invalidPragma(n)
      return 
    case whichKeyword(n.sons[1].ident)
    of wOn: incl(gNotes, nk)
    of wOff: excl(gNotes, nk)
    else: liMessage(n.info, errOnOrOffExpected)
  else: 
    invalidPragma(n)
  
proc processOption(c: PContext, n: PNode) = 
  var sw: TSpecialWord
  if n.kind != nkExprColonExpr: 
    invalidPragma(n)
  elif n.sons[0].kind == nkBracketExpr: 
    processNote(c, n)
  elif n.sons[0].kind != nkIdent: 
    invalidPragma(n)
  else: 
    sw = whichKeyword(n.sons[0].ident)
    case sw
    of wChecks: 
      OnOff(c, n, checksOptions)
    of wObjChecks: 
      OnOff(c, n, {optObjCheck})
    of wFieldchecks: 
      OnOff(c, n, {optFieldCheck})
    of wRangechecks: 
      OnOff(c, n, {optRangeCheck})
    of wBoundchecks: 
      OnOff(c, n, {optBoundsCheck})
    of wOverflowchecks: 
      OnOff(c, n, {optOverflowCheck})
    of wNilchecks: 
      OnOff(c, n, {optNilCheck})
    of wAssertions: 
      OnOff(c, n, {optAssert})
    of wWarnings: 
      OnOff(c, n, {optWarns})
    of wHints: 
      OnOff(c, n, {optHints})
    of wCallConv: 
      processCallConv(c, n)   # ------ these are not in the Nimrod spec: -------------
    of wLinedir: 
      OnOff(c, n, {optLineDir})
    of wStacktrace: 
      OnOff(c, n, {optStackTrace})
    of wLinetrace: 
      OnOff(c, n, {optLineTrace})
    of wDebugger: 
      OnOff(c, n, {optEndb})
    of wProfiler: 
      OnOff(c, n, {optProfiler})
    of wByRef: 
      OnOff(c, n, {optByRef})
    of wDynLib: 
      processDynLib(c, n, nil) # 
                               # -------------------------------------------------------
    of wOptimization: 
      if n.sons[1].kind != nkIdent: 
        invalidPragma(n)
      else: 
        case whichKeyword(n.sons[1].ident)
        of wSpeed: 
          incl(gOptions, optOptimizeSpeed)
          excl(gOptions, optOptimizeSize)
        of wSize: 
          excl(gOptions, optOptimizeSpeed)
          incl(gOptions, optOptimizeSize)
        of wNone: 
          excl(gOptions, optOptimizeSpeed)
          excl(gOptions, optOptimizeSize)
        else: liMessage(n.info, errNoneSpeedOrSizeExpected)
    else: liMessage(n.info, errOptionExpected)
  
proc processPush(c: PContext, n: PNode, start: int) = 
  var x, y: POptionEntry
  x = newOptionEntry()
  y = POptionEntry(c.optionStack.tail)
  x.options = gOptions
  x.defaultCC = y.defaultCC
  x.dynlib = y.dynlib
  x.notes = gNotes
  append(c.optionStack, x)
  for i in countup(start, sonsLen(n) - 1): 
    processOption(c, n.sons[i]) #liMessage(n.info, warnUser, ropeToStr(optionsToStr(gOptions)));
  
proc processPop(c: PContext, n: PNode) = 
  if c.optionStack.counter <= 1: 
    liMessage(n.info, errAtPopWithoutPush)
  else: 
    gOptions = POptionEntry(c.optionStack.tail).options #liMessage(n.info, warnUser, ropeToStr(optionsToStr(gOptions)));
    gNotes = POptionEntry(c.optionStack.tail).notes
    remove(c.optionStack, c.optionStack.tail)

proc processDefine(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    DefineSymbol(n.sons[1].ident.s)
    liMessage(n.info, warnDeprecated, "define")
  else: 
    invalidPragma(n)
  
proc processUndef(c: PContext, n: PNode) = 
  if (n.kind == nkExprColonExpr) and (n.sons[1].kind == nkIdent): 
    UndefSymbol(n.sons[1].ident.s)
    liMessage(n.info, warnDeprecated, "undef")
  else: 
    invalidPragma(n)
  
type 
  TLinkFeature = enum 
    linkNormal, linkSys

proc processCompile(c: PContext, n: PNode) = 
  var s, found, trunc: string
  s = expectStrLit(c, n)
  found = findFile(s)
  if found == "": found = s
  trunc = ChangeFileExt(found, "")
  extccomp.addExternalFileToCompile(trunc)
  extccomp.addFileToLink(completeCFilePath(trunc, false))

proc processCommonLink(c: PContext, n: PNode, feature: TLinkFeature) = 
  var f, found: string
  f = expectStrLit(c, n)
  if splitFile(f).ext == "": f = toObjFile(f)
  found = findFile(f)
  if found == "": 
    found = f                 # use the default
  case feature
  of linkNormal: 
    extccomp.addFileToLink(found)
  of linkSys: 
    extccomp.addFileToLink(joinPath(libpath, completeCFilePath(found, false)))
  else: internalError(n.info, "processCommonLink")
  
proc PragmaBreakpoint(c: PContext, n: PNode) = 
  discard getOptionalStr(c, n, "")

proc PragmaCheckpoint(c: PContext, n: PNode) = 
  # checkpoints can be used to debug the compiler; they are not documented
  var info: TLineInfo
  info = n.info
  inc(info.line)              # next line is affected!
  msgs.addCheckpoint(info)

proc noVal(n: PNode) = 
  if n.kind == nkExprColonExpr: invalidPragma(n)
  
proc pragma(c: PContext, sym: PSym, n: PNode, validPragmas: TSpecialWords) = 
  var 
    key, it: PNode
    k: TSpecialWord
    lib: PLib
  if n == nil: return 
  for i in countup(0, sonsLen(n) - 1): 
    it = n.sons[i]
    if it.kind == nkExprColonExpr: key = it.sons[0]
    else: key = it
    if key.kind == nkIdent: 
      k = whichKeyword(key.ident)
      if k in validPragmas: 
        case k
        of wExportc: 
          makeExternExport(sym, getOptionalStr(c, it, sym.name.s))
          incl(sym.flags, sfUsed) # avoid wrong hints
        of wImportc: 
          makeExternImport(sym, getOptionalStr(c, it, sym.name.s))
        of wAlign: 
          if sym.typ == nil: invalidPragma(it)
          sym.typ.align = expectIntLit(c, it)
          if not IsPowerOfTwo(sym.typ.align) and (sym.typ.align != 0): 
            liMessage(it.info, errPowerOfTwoExpected)
        of wNodecl: 
          noVal(it)
          incl(sym.loc.Flags, lfNoDecl)
        of wPure: 
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
          incl(sym.flags, sfThreadVar)
        of wDeadCodeElim: 
          pragmaDeadCodeElim(c, it)
        of wMagic: 
          processMagic(c, it, sym)
        of wCompileTime: 
          noVal(it)
          incl(sym.flags, sfCompileTime)
          incl(sym.loc.Flags, lfNoDecl)
        of wMerge: 
          noval(it)
          incl(sym.flags, sfMerge)
        of wHeader: 
          lib = getLib(c, libHeader, expectStrLit(c, it))
          addToLib(lib, sym)
          incl(sym.flags, sfImportc)
          incl(sym.loc.flags, lfHeader)
          incl(sym.loc.Flags, lfNoDecl) # implies nodecl, because
                                        # otherwise header would not make sense
          if sym.loc.r == nil: sym.loc.r = toRope(sym.name.s)
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
          makeExternExport(sym, sym.name.s)
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
          incl(sym.typ.flags, tfVarargs)
        of wBorrow: 
          noVal(it)
          incl(sym.flags, sfBorrow)
        of wFinal: 
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          incl(sym.typ.flags, tfFinal)
        of wAcyclic: 
          noVal(it)
          if sym.typ == nil: invalidPragma(it)
          incl(sym.typ.flags, tfAcyclic)
        of wTypeCheck: 
          noVal(it)
          incl(sym.flags, sfTypeCheck)
        of wHint: 
          liMessage(it.info, hintUser, expectStrLit(c, it))
        of wWarning: 
          liMessage(it.info, warnUser, expectStrLit(c, it))
        of wError: 
          liMessage(it.info, errUser, expectStrLit(c, it))
        of wFatal: 
          liMessage(it.info, errUser, expectStrLit(c, it))
          quit(1)
        of wDefine: 
          processDefine(c, it)
        of wUndef: 
          processUndef(c, it)
        of wCompile: 
          processCompile(c, it)
        of wLink: 
          processCommonLink(c, it, linkNormal)
        of wLinkSys: 
          processCommonLink(c, it, linkSys)
        of wPassL: 
          extccomp.addLinkOption(expectStrLit(c, it))
        of wPassC: 
          extccomp.addCompileOption(expectStrLit(c, it))
        of wBreakpoint: 
          PragmaBreakpoint(c, it)
        of wCheckpoint: 
          PragmaCheckpoint(c, it)
        of wPush: 
          processPush(c, n, i + 1)
          break 
        of wPop: 
          processPop(c, it)
        of wChecks, wObjChecks, wFieldChecks, wRangechecks, wBoundchecks, 
           wOverflowchecks, wNilchecks, wAssertions, wWarnings, wHints, 
           wLinedir, wStacktrace, wLinetrace, wOptimization, wByRef, wCallConv, 
           wDebugger, wProfiler: 
          processOption(c, it) # calling conventions (boring...):
        of firstCallConv..lastCallConv: 
          assert(sym != nil)
          if sym.typ == nil: invalidPragma(it)
          sym.typ.callConv = wordToCallConv(k)
        else: invalidPragma(it)
      else: 
        invalidPragma(it)
    else: 
      processNote(c, it)
  if (sym != nil) and (sym.kind != skModule): 
    if (lfExportLib in sym.loc.flags) and not (sfExportc in sym.flags): 
      liMessage(n.info, errDynlibRequiresExportc)
    lib = POptionEntry(c.optionstack.tail).dynlib
    if ({lfDynamicLib, lfHeader} * sym.loc.flags == {}) and
        (sfImportc in sym.flags) and (lib != nil): 
      incl(sym.loc.flags, lfDynamicLib)
      addToLib(lib, sym)
      if sym.loc.r == nil: sym.loc.r = toRope(sym.name.s)
  