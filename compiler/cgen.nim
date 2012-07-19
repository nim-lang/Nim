#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the C code generator.

import 
  ast, astalgo, strutils, hashes, trees, platform, magicsys, extccomp,
  options, intsets,
  nversion, nimsets, msgs, crc, bitsets, idents, lists, types, ccgutils, os,
  times, ropes, math, passes, rodread, wordrecg, treetab, cgmeth,
  rodutils, renderer, idgen, cgendata, ccgmerge, semfold, aliases

when options.hasTinyCBackend:
  import tccgen

proc cgenPass*(): TPass
# implementation

proc ropeff(cformat, llvmformat: string, args: openarray[PRope]): PRope = 
  if gCmd == cmdCompileToLLVM: result = ropef(llvmformat, args)
  else: result = ropef(cformat, args)
  
proc appff(dest: var PRope, cformat, llvmformat: string, 
           args: openarray[PRope]) = 
  if gCmd == cmdCompileToLLVM: appf(dest, llvmformat, args)
  else: appf(dest, cformat, args)
  
proc addForwardedProc(m: BModule, prc: PSym) = 
  m.forwardedProcs.add(prc)
  inc(gForwardedProcsCounter)

proc addPendingModule(m: BModule) = 
  for i in countup(0, high(gPendingModules)): 
    if gPendingModules[i] == m: 
      InternalError("module already pending: " & m.module.name.s)
  gPendingModules.add(m)

proc findPendingModule(m: BModule, s: PSym): BModule = 
  var ms = getModule(s)
  if ms.id == m.module.id: return m
  for i in countup(0, high(gPendingModules)): 
    result = gPendingModules[i]
    if result.module.id == ms.id: return 
  # else we found no pending module: This can happen for procs that are in
  # a module that is already closed. This is fine, don't generate code for
  # it then:
  result = nil
  #InternalError(s.info, "no pending module found for: " & s.name.s)

proc emitLazily(s: PSym): bool {.inline.} =
  result = optDeadCodeElim in gGlobalOptions or
           sfDeadCodeElim in getModule(s).flags

proc initLoc(result: var TLoc, k: TLocKind, typ: PType, s: TStorageLoc) = 
  result.k = k
  result.s = s
  result.t = GetUniqueType(typ)
  result.r = nil
  result.a = - 1
  result.flags = {}

proc fillLoc(a: var TLoc, k: TLocKind, typ: PType, r: PRope, s: TStorageLoc) = 
  # fills the loc if it is not already initialized
  if a.k == locNone: 
    a.k = k
    a.t = getUniqueType(typ)
    a.a = - 1
    a.s = s
    if a.r == nil: a.r = r
  
proc isSimpleConst(typ: PType): bool =
  let t = skipTypes(typ, abstractVar)
  result = t.kind notin
      {tyTuple, tyObject, tyArray, tyArrayConstr, tySet, tySequence} and not
      (t.kind == tyProc and t.callConv == ccClosure)

proc useHeader(m: BModule, sym: PSym) = 
  if lfHeader in sym.loc.Flags: 
    assert(sym.annex != nil)
    discard lists.IncludeStr(m.headerFiles, getStr(sym.annex.path))

proc cgsym(m: BModule, name: string): PRope

proc ropecg(m: BModule, frmt: TFormatStr, args: openarray[PRope]): PRope = 
  var i = 0
  var length = len(frmt)
  result = nil
  var num = 0
  while i < length: 
    if frmt[i] == '$': 
      inc(i)                  # skip '$'
      case frmt[i]
      of '$': 
        app(result, "$")
        inc(i)
      of '#': 
        inc(i)
        app(result, args[num])
        inc(num)
      of '0'..'9': 
        var j = 0
        while true: 
          j = (j * 10) + Ord(frmt[i]) - ord('0')
          inc(i)
          if i >= length or not (frmt[i] in {'0'..'9'}): break 
        num = j
        if j > high(args) + 1: 
          internalError("ropes: invalid format string $" & $j)
        app(result, args[j-1])
      of 'n':
        if optLineDir notin gOptions: app(result, tnl)
        inc(i)
      of 'N': 
        app(result, tnl)
        inc(i)
      else: InternalError("ropes: invalid format string $" & frmt[i])
    elif frmt[i] == '#' and frmt[i+1] in IdentStartChars:
      inc(i)
      var j = i
      while frmt[j] in IdentChars: inc(j)
      var ident = substr(frmt, i, j-1)
      i = j
      app(result, cgsym(m, ident))
    elif frmt[i] == '#' and frmt[i+1] == '$':
      inc(i, 2)
      var j = 0
      while frmt[i] in Digits: 
        j = (j * 10) + Ord(frmt[i]) - ord('0')
        inc(i)
      app(result, cgsym(m, args[j-1].ropeToStr))
    var start = i
    while i < length: 
      if frmt[i] != '$' and frmt[i] != '#': inc(i)
      else: break 
    if i - 1 >= start: 
      app(result, substr(frmt, start, i - 1))

proc appcg(m: BModule, c: var PRope, frmt: TFormatStr, 
           args: openarray[PRope]) = 
  app(c, ropecg(m, frmt, args))

proc appcg(m: BModule, s: TCFileSection, frmt: TFormatStr, 
           args: openarray[PRope]) = 
  app(m.s[s], ropecg(m, frmt, args))

proc appcg(p: BProc, s: TCProcSection, frmt: TFormatStr, 
           args: openarray[PRope]) = 
  app(p.s(s), ropecg(p.module, frmt, args))

var indent = "\t".toRope
proc indentLine(p: BProc, r: PRope): PRope =
  result = r
  for i in countup(0, p.blocks.len-1): prepend(result, indent)
  
proc line(p: BProc, s: TCProcSection, r: PRope) =
  app(p.s(s), indentLine(p, r))

proc line(p: BProc, s: TCProcSection, r: string) =
  app(p.s(s), indentLine(p, r.toRope))

proc lineF(p: BProc, s: TCProcSection, frmt: TFormatStr,
              args: openarray[PRope]) =
  app(p.s(s), indentLine(p, ropef(frmt, args)))

proc lineCg(p: BProc, s: TCProcSection, frmt: TFormatStr,
               args: openarray[PRope]) =
  app(p.s(s), indentLine(p, ropecg(p.module, frmt, args)))

proc appLineCg(p: BProc, r: var PRope, frmt: TFormatStr,
               args: openarray[PRope]) =
  app(r, indentLine(p, ropecg(p.module, frmt, args)))

proc lineFF(p: BProc, s: TCProcSection, cformat, llvmformat: string,
               args: openarray[PRope]) =
  if gCmd == cmdCompileToLLVM: lineF(p, s, llvmformat, args)
  else: lineF(p, s, cformat, args)

proc safeLineNm(info: TLineInfo): int =
  result = toLinenumber(info)
  if result < 0: result = 0 # negative numbers are not allowed in #line

proc genCLineDir(r: var PRope, filename: string, line: int) =
  assert line >= 0
  if optLineDir in gOptions:
    appff(r, "$N#line $2 $1$N", "; line $2 \"$1\"$n",
          [toRope(makeSingleLineCString(filename)), toRope(line)])

proc genCLineDir(r: var PRope, info: TLineInfo) = 
  genCLineDir(r, info.toFullPath, info.safeLineNm)

proc genLineDir(p: BProc, t: PNode) = 
  var line = t.info.safeLineNm
  genCLineDir(p.s(cpsStmts), t.info.toFullPath, line)
  if ({optStackTrace, optEndb} * p.Options == {optStackTrace, optEndb}) and
      (p.prc == nil or sfPure notin p.prc.flags): 
    lineCg(p, cpsStmts, "#endb($1);$n", [toRope(line)])
  elif ({optLineTrace, optStackTrace} * p.Options ==
      {optLineTrace, optStackTrace}) and
      (p.prc == nil or sfPure notin p.prc.flags): 
    lineF(p, cpsStmts, "F.line = $1;F.filename = $2;$n", 
        [toRope(line), makeCString(toFilename(t.info).extractFilename)])

include "ccgtypes.nim"

# ------------------------------ Manager of temporaries ------------------

proc rdLoc(a: TLoc): PRope =
  # 'read' location (deref if indirect)
  result = a.r
  if lfIndirect in a.flags: result = ropef("(*$1)", [result])

proc addrLoc(a: TLoc): PRope =
  result = a.r
  if lfIndirect notin a.flags and mapType(a.t) != ctArray:
    result = con("&", result)

proc rdCharLoc(a: TLoc): PRope =
  # read a location that may need a char-cast:
  result = rdLoc(a)
  if skipTypes(a.t, abstractRange).kind == tyChar:
    result = ropef("((NU8)($1))", [result])

proc genObjectInit(p: BProc, section: TCProcSection, t: PType, a: TLoc,
                   takeAddr: bool) =
  case analyseObjectWithTypeField(t)
  of frNone:
    nil
  of frHeader:
    var r = rdLoc(a)
    if not takeAddr: r = ropef("(*$1)", [r])
    var s = skipTypes(t, abstractInst)
    if gCmd != cmdCompileToCpp:
      while (s.kind == tyObject) and (s.sons[0] != nil):
        app(r, ".Sup")
        s = skipTypes(s.sons[0], abstractInst)
    lineCg(p, section, "$1.m_type = $2;$n", [r, genTypeInfo(p.module, t)])
  of frEmbedded:
    # worst case for performance:
    var r = if takeAddr: addrLoc(a) else: rdLoc(a)
    lineCg(p, section, "#objectInit($1, $2);$n", [r, genTypeInfo(p.module, t)])

type
  TAssignmentFlag = enum
    needToCopy, needForSubtypeCheck, afDestIsNil, afDestIsNotNil, afSrcIsNil,
    afSrcIsNotNil, needToKeepAlive
  TAssignmentFlags = set[TAssignmentFlag]

proc genRefAssign(p: BProc, dest, src: TLoc, flags: TAssignmentFlags)

proc isComplexValueType(t: PType): bool {.inline.} =
  result = t.kind in {tyArray, tyArrayConstr, tySet, tyTuple, tyObject} or
    (t.kind == tyProc and t.callConv == ccClosure)

proc resetLoc(p: BProc, loc: var TLoc) =
  let containsGcRef = containsGarbageCollectedRef(loc.t)
  if not isComplexValueType(skipTypes(loc.t, abstractVarRange)):
    if containsGcRef:
      var nilLoc: TLoc
      initLoc(nilLoc, locTemp, loc.t, onStack)
      nilLoc.r = toRope("NIM_NIL")
      genRefAssign(p, loc, nilLoc, {afSrcIsNil})
    else:
      lineF(p, cpsStmts, "$1 = 0;$n", [rdLoc(loc)])
  else:
    if loc.s != OnStack:
      lineCg(p, cpsStmts, "#genericReset((void*)$1, $2);$n",
        [addrLoc(loc), genTypeInfo(p.module, loc.t)])
      # XXX: generated reset procs should not touch the m_type
      # field, so disabling this should be safe:
      genObjectInit(p, cpsStmts, loc.t, loc, true)
    else:
      lineF(p, cpsStmts, "memset((void*)$1, 0, sizeof($2));$n",
        [addrLoc(loc), rdLoc(loc)])
      # XXX: We can be extra clever here and call memset only 
      # on the bytes following the m_type field?
      genObjectInit(p, cpsStmts, loc.t, loc, true)

proc constructLoc(p: BProc, loc: TLoc, section = cpsStmts) =
  if not isComplexValueType(skipTypes(loc.t, abstractVarRange)):
    lineF(p, section, "$1 = 0;$n", [rdLoc(loc)])
  else:
    lineF(p, section, "memset((void*)$1, 0, sizeof($2));$n",
       [addrLoc(loc), rdLoc(loc)])
    genObjectInit(p, section, loc.t, loc, true)

proc initLocalVar(p: BProc, v: PSym, immediateAsgn: bool) =
  if sfNoInit notin v.flags:
    # we know it is a local variable and thus on the stack!
    # If ``not immediateAsgn`` it is not initialized in a binding like
    # ``var v = X`` and thus we need to init it. 
    # If ``v`` contains a GC-ref we may pass it to ``unsureAsgnRef`` somehow
    # which requires initialization. However this can really only happen if
    # ``var v = X()`` gets transformed into ``X(&v)``. 
    # Nowadays the logic in ccgcalls deals with this case however.
    if not immediateAsgn:
      constructLoc(p, v.loc)

proc initTemp(p: BProc, tmp: var TLoc) =
  # XXX: This is still suspicious.
  # Objects should always be constructed?
  if containsGarbageCollectedRef(tmp.t) or isInvalidReturnType(tmp.t):
    constructLoc(p, tmp)

proc getTemp(p: BProc, t: PType, result: var TLoc) = 
  inc(p.labels)
  if gCmd == cmdCompileToLLVM: 
    result.r = con("%LOC", toRope(p.labels))
  else: 
    result.r = con("LOC", toRope(p.labels))
    lineF(p, cpsLocals, "$1 $2;$n", [getTypeDesc(p.module, t), result.r])
  result.k = locTemp
  result.a = - 1
  result.t = getUniqueType(t)
  result.s = OnStack
  result.flags = {}
  initTemp(p, result)

proc keepAlive(p: BProc, toKeepAlive: TLoc) =
  when false:
    # deactivated because of the huge slowdown this causes; GC will take care
    # of interior pointers instead
    if optRefcGC notin gGlobalOptions: return
    var result: TLoc
    var fid = toRope(p.gcFrameId)
    result.r = con("GCFRAME.F", fid)
    appf(p.gcFrameType, "  $1 F$2;$n",
        [getTypeDesc(p.module, toKeepAlive.t), fid])
    inc(p.gcFrameId)
    result.k = locTemp
    result.a = -1
    result.t = toKeepAlive.t
    result.s = OnStack
    result.flags = {}

    if not isComplexValueType(skipTypes(toKeepAlive.t, abstractVarRange)):
      lineF(p, cpsStmts, "$1 = $2;$n", [rdLoc(result), rdLoc(toKeepAlive)])
    else:
      lineCg(p, cpsStmts,
           "memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($3));$n",
           [addrLoc(result), addrLoc(toKeepAlive), rdLoc(result)])

proc initGCFrame(p: BProc): PRope =
  if p.gcFrameId > 0: result = ropef("struct {$1} GCFRAME;$n", p.gcFrameType)

proc deinitGCFrame(p: BProc): PRope =
  if p.gcFrameId > 0:
    result = ropecg(p.module,
                    "if (((NU)&GCFRAME) < 4096) #nimGCFrame(&GCFRAME);$n")

proc cstringLit(p: BProc, r: var PRope, s: string): PRope = 
  if gCmd == cmdCompileToLLVM: 
    inc(p.module.labels)
    inc(p.labels)
    result = ropef("%LOC$1", [toRope(p.labels)])
    appf(p.module.s[cfsData], "@C$1 = private constant [$2 x i8] $3$n", 
         [toRope(p.module.labels), toRope(len(s)), makeLLVMString(s)])
    appf(r, "$1 = getelementptr [$2 x i8]* @C$3, %NI 0, %NI 0$n", 
         [result, toRope(len(s)), toRope(p.module.labels)])
  else: 
    result = makeCString(s)
  
proc cstringLit(m: BModule, r: var PRope, s: string): PRope = 
  if gCmd == cmdCompileToLLVM: 
    inc(m.labels, 2)
    result = ropef("%MOC$1", [toRope(m.labels - 1)])
    appf(m.s[cfsData], "@MOC$1 = private constant [$2 x i8] $3$n", 
         [toRope(m.labels), toRope(len(s)), makeLLVMString(s)])
    appf(r, "$1 = getelementptr [$2 x i8]* @MOC$3, %NI 0, %NI 0$n", 
         [result, toRope(len(s)), toRope(m.labels)])
  else: 
    result = makeCString(s)
  
proc allocParam(p: BProc, s: PSym) = 
  assert(s.kind == skParam)
  if lfParamCopy notin s.loc.flags: 
    inc(p.labels)
    var tmp = con("%LOC", toRope(p.labels))
    incl(s.loc.flags, lfParamCopy)
    incl(s.loc.flags, lfIndirect)
    lineF(p, cpsInit, "$1 = alloca $3$n" & "store $3 $2, $3* $1$n",
         [tmp, s.loc.r, getTypeDesc(p.module, s.loc.t)])
    s.loc.r = tmp

proc localDebugInfo(p: BProc, s: PSym) = 
  if {optStackTrace, optEndb} * p.options != {optStackTrace, optEndb}: return 
  # XXX work around a bug: No type information for open arrays possible:
  if skipTypes(s.typ, abstractVar).kind == tyOpenArray: return
  var a = con("&", s.loc.r)
  if (s.kind == skParam) and ccgIntroducedPtr(s): a = s.loc.r
  lineF(p, cpsInit,
       "F.s[$1].address = (void*)$3; F.s[$1].typ = $4; F.s[$1].name = $2;$n",
       [toRope(p.frameLen), makeCString(normalize(s.name.s)), a, 
        genTypeInfo(p.module, s.loc.t)])
  inc(p.frameLen)

proc assignLocalVar(p: BProc, s: PSym) = 
  #assert(s.loc.k == locNone) // not yet assigned
  # this need not be fullfilled for inline procs; they are regenerated
  # for each module that uses them!
  if s.loc.k == locNone: 
    fillLoc(s.loc, locLocalVar, s.typ, mangleName(s), OnStack)
    if s.kind == skLet: incl(s.loc.flags, lfNoDeepCopy)
  var decl = getTypeDesc(p.module, s.loc.t)
  if sfRegister in s.flags: app(decl, " register")
  #elif skipTypes(s.typ, abstractInst).kind in GcTypeKinds:
  #  app(decl, " GC_GUARD")
  if (sfVolatile in s.flags) or (p.nestedTryStmts.len > 0): 
    app(decl, " volatile")
  appf(decl, " $1;$n", [s.loc.r])
  line(p, cpsLocals, decl)
  localDebugInfo(p, s)

include ccgthreadvars

proc VarInDynamicLib(m: BModule, sym: PSym)
proc mangleDynLibProc(sym: PSym): PRope

proc assignGlobalVar(p: BProc, s: PSym) = 
  if s.loc.k == locNone: 
    fillLoc(s.loc, locGlobalVar, s.typ, mangleName(s), OnHeap)
  
  if lfDynamicLib in s.loc.flags:
    var q = findPendingModule(p.module, s)
    if q != nil and not ContainsOrIncl(q.declaredThings, s.id): 
      VarInDynamicLib(q, s)
    else:
      s.loc.r = mangleDynLibProc(s)
    return
  useHeader(p.module, s)
  if lfNoDecl in s.loc.flags: return
  if sfThread in s.flags: 
    declareThreadVar(p.module, s, sfImportc in s.flags)
  else: 
    if sfImportc in s.flags: app(p.module.s[cfsVars], "extern ")
    app(p.module.s[cfsVars], getTypeDesc(p.module, s.loc.t))
    if sfRegister in s.flags: app(p.module.s[cfsVars], " register")
    if sfVolatile in s.flags: app(p.module.s[cfsVars], " volatile")
    appf(p.module.s[cfsVars], " $1;$n", [s.loc.r])
  if p.withinLoop > 0:
    # fixes tests/run/tzeroarray:
    resetLoc(p, s.loc)
  if p.module.module.options * {optStackTrace, optEndb} ==
                               {optStackTrace, optEndb}: 
    appcg(p.module, p.module.s[cfsDebugInit], 
          "#dbgRegisterGlobal($1, &$2, $3);$n", 
         [cstringLit(p, p.module.s[cfsDebugInit], 
          normalize(s.owner.name.s & '.' & s.name.s)), 
          s.loc.r, genTypeInfo(p.module, s.typ)])
  
proc assignParam(p: BProc, s: PSym) = 
  assert(s.loc.r != nil)
  if sfAddrTaken in s.flags and gCmd == cmdCompileToLLVM: allocParam(p, s)
  localDebugInfo(p, s)

proc fillProcLoc(sym: PSym) = 
  if sym.loc.k == locNone: 
    fillLoc(sym.loc, locProc, sym.typ, mangleName(sym), OnStack)
  
proc getLabel(p: BProc): TLabel = 
  inc(p.labels)
  result = con("LA", toRope(p.labels))

proc fixLabel(p: BProc, labl: TLabel) = 
  lineF(p, cpsStmts, "$1: ;$n", [labl])

proc genVarPrototype(m: BModule, sym: PSym)
proc requestConstImpl(p: BProc, sym: PSym)
proc genProc(m: BModule, prc: PSym)
proc genStmts(p: BProc, t: PNode)
proc genProcPrototype(m: BModule, sym: PSym)

include "ccgexprs.nim", "ccgstmts.nim"

# ----------------------------- dynamic library handling -----------------
# We don't finalize dynamic libs as this does the OS for us.

proc libCandidates(s: string, dest: var TStringSeq) = 
  var le = strutils.find(s, '(')
  var ri = strutils.find(s, ')', le+1)
  if le >= 0 and ri > le:
    var prefix = substr(s, 0, le - 1)
    var suffix = substr(s, ri + 1)
    for middle in split(substr(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else: 
    add(dest, s)

proc loadDynamicLib(m: BModule, lib: PLib) = 
  assert(lib != nil)
  if not lib.generated: 
    lib.generated = true
    var tmp = getGlobalTempName()
    assert(lib.name == nil)
    lib.name = tmp # BUGFIX: cgsym has awful side-effects
    appf(m.s[cfsVars], "static void* $1;$n", [tmp])
    if lib.path.kind in {nkStrLit..nkTripleStrLit}:
      var s: TStringSeq = @[]
      libCandidates(lib.path.strVal, s)
      var loadlib: PRope = nil
      for i in countup(0, high(s)): 
        inc(m.labels)
        if i > 0: app(loadlib, "||")
        appcg(m, loadlib, "($1 = #nimLoadLibrary((#NimStringDesc*) &$2))$n", 
              [tmp, getStrLit(m, s[i])])
      appcg(m, m.s[cfsDynLibInit], 
            "if (!($1)) #nimLoadLibraryError((#NimStringDesc*) &$2);$n", 
            [loadlib, getStrLit(m, lib.path.strVal)]) 
    else:
      var p = newProc(nil, m)
      var dest: TLoc
      initLocExpr(p, lib.path, dest)
      app(m.s[cfsVars], p.s(cpsLocals))
      app(m.s[cfsDynLibInit], p.s(cpsInit))
      app(m.s[cfsDynLibInit], p.s(cpsStmts))
      appcg(m, m.s[cfsDynLibInit], 
           "if (!($1 = #nimLoadLibrary($2))) #nimLoadLibraryError($2);$n", 
           [tmp, rdLoc(dest)])
      
  if lib.name == nil: InternalError("loadDynamicLib")
  
proc mangleDynLibProc(sym: PSym): PRope =
  if sfCompilerProc in sym.flags: 
    # NOTE: sym.loc.r is the external name!
    result = toRope(sym.name.s)
  else:
    result = ropef("Dl_$1", [toRope(sym.id)])
  
proc SymInDynamicLib(m: BModule, sym: PSym) = 
  var lib = sym.annex
  var extname = sym.loc.r
  loadDynamicLib(m, lib)
  if gCmd == cmdCompileToLLVM: incl(sym.loc.flags, lfIndirect)
  var tmp = mangleDynLibProc(sym)
  sym.loc.r = tmp             # from now on we only need the internal name
  sym.typ.sym = nil           # generate a new name
  inc(m.labels, 2)
  appcg(m, m.s[cfsDynLibInit], 
      "$1 = ($2) #nimGetProcAddr($3, $4);$n", 
      [tmp, getTypeDesc(m, sym.typ), 
      lib.name, cstringLit(m, m.s[cfsDynLibInit], ropeToStr(extname))])
  appff(m.s[cfsVars], "$2 $1;$n", 
      "$1 = linkonce global $2 zeroinitializer$n", 
      [sym.loc.r, getTypeDesc(m, sym.loc.t)])

proc VarInDynamicLib(m: BModule, sym: PSym) = 
  var lib = sym.annex
  var extname = sym.loc.r
  loadDynamicLib(m, lib)
  incl(sym.loc.flags, lfIndirect)
  var tmp = mangleDynLibProc(sym)
  sym.loc.r = tmp             # from now on we only need the internal name
  inc(m.labels, 2)
  appcg(m, m.s[cfsDynLibInit], 
      "$1 = ($2*) #nimGetProcAddr($3, $4);$n", 
      [tmp, getTypeDesc(m, sym.typ), 
      lib.name, cstringLit(m, m.s[cfsDynLibInit], ropeToStr(extname))])
  appf(m.s[cfsVars], "$2* $1;$n",
      [sym.loc.r, getTypeDesc(m, sym.loc.t)])

proc SymInDynamicLibPartial(m: BModule, sym: PSym) =
  sym.loc.r = mangleDynLibProc(sym)
  sym.typ.sym = nil           # generate a new name

proc cgsym(m: BModule, name: string): PRope = 
  var sym = magicsys.getCompilerProc(name)
  if sym != nil: 
    case sym.kind
    of skProc, skMethod, skConverter: genProc(m, sym)
    of skVar, skResult, skLet: genVarPrototype(m, sym)
    of skType: discard getTypeDesc(m, sym.typ)
    else: InternalError("cgsym: " & name)
  else:
    # we used to exclude the system module from this check, but for DLL
    # generation support this sloppyness leads to hard to detect bugs, so
    # we're picky here for the system module too:
    rawMessage(errSystemNeeds, name)
  result = sym.loc.r
  
proc generateHeaders(m: BModule) = 
  app(m.s[cfsHeaders], tnl & "#include \"nimbase.h\"" & tnl)
  var it = PStrEntry(m.headerFiles.head)
  while it != nil: 
    if it.data[0] notin {'\"', '<'}: 
      appf(m.s[cfsHeaders], "$N#include \"$1\"$N", [toRope(it.data)])
    else: 
      appf(m.s[cfsHeaders], "$N#include $1$N", [toRope(it.data)])
    it = PStrEntry(it.Next)

proc getFrameDecl(p: BProc) = 
  var slots: PRope
  if p.frameLen > 0: 
    discard cgsym(p.module, "TVarSlot")
    slots = ropeff("  TVarSlot s[$1];$n", ", [$1 x %TVarSlot]", 
                   [toRope(p.frameLen)])
  else: 
    slots = nil
  lineFF(p, cpsLocals, "volatile struct {TFrame* prev;" &
      "NCSTRING procname;NI line;NCSTRING filename;" &
      "NI len;$1} F;$n",
      "%TF = type {%TFrame*, i8*, %NI, %NI$1}$n" & 
      "%F = alloca %TF$n", [slots])
  inc(p.labels)
  prepend(p.s(cpsInit), indentLine(p, ropeff("F.len = $1;$n", 
      "%LOC$2 = getelementptr %TF %F, %NI 4$n" &
      "store %NI $1, %NI* %LOC$2$n", [toRope(p.frameLen), toRope(p.labels)])))

proc retIsNotVoid(s: PSym): bool = 
  result = (s.typ.sons[0] != nil) and not isInvalidReturnType(s.typ.sons[0])

proc initFrame(p: BProc, procname, filename: PRope): PRope = 
  result = ropecg(p.module, 
    "\tF.procname = $1;$n" &
    "\tF.filename = $2;$n" & 
    "\tF.line = 0;$n" & 
    "\t#pushFrame((TFrame*)&F);$n", [procname, filename])

proc deinitFrame(p: BProc): PRope =
  result = ropecg(p.module, "\t#popFrame();$n")

proc closureSetup(p: BProc, prc: PSym) =
  if prc.typ.callConv != ccClosure: return
  # prc.ast[paramsPos].last contains the type we're after:
  var ls = lastSon(prc.ast[paramsPos])
  if ls.kind != nkSym:
    InternalError(prc.info, "closure generation failed")
  var env = ls.sym
  #echo "created environment: ", env.id, " for ", prc.name.s
  assignLocalVar(p, env)
  # generate cast assignment:
  lineCg(p, cpsStmts, "$1 = ($2) ClEnv;$n", rdLoc(env.loc),
         getTypeDesc(p.module, env.typ))

proc genProcAux(m: BModule, prc: PSym) =
  var p = newProc(prc, m)
  var header = genProcHeader(m, prc)
  var returnStmt: PRope = nil
  assert(prc.ast != nil)
  if sfPure notin prc.flags and prc.typ.sons[0] != nil:
    var res = prc.ast.sons[resultPos].sym # get result symbol
    if not isInvalidReturnType(prc.typ.sons[0]):
      if sfNoInit in prc.flags: incl(res.flags, sfNoInit)
      # declare the result symbol:
      assignLocalVar(p, res)
      assert(res.loc.r != nil)
      returnStmt = ropeff("\treturn $1;$n", "ret $1$n", [rdLoc(res.loc)])
      initLocalVar(p, res, immediateAsgn=false)
    else:
      fillResult(res)
      assignParam(p, res)
      if skipTypes(res.typ, abstractInst).kind == tyArray: 
        incl(res.loc.flags, lfIndirect)
        res.loc.s = OnUnknown
  for i in countup(1, sonsLen(prc.typ.n) - 1): 
    var param = prc.typ.n.sons[i].sym
    if param.typ.isCompileTimeOnly: continue
    assignParam(p, param)
  closureSetup(p, prc)
  genStmts(p, prc.getBody) # modifies p.locals, p.init, etc.
  var generatedProc: PRope
  if sfPure in prc.flags: 
    generatedProc = ropeff("$N$1 {$n$2$3$4}$N$N", "define $1 {$n$2$3$4}$N",
        [header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts)])
  else:
    generatedProc = ropeff("$N$1 {$N", "$Ndefine $1 {$N", [header])
    app(generatedProc, initGCFrame(p))
    if optStackTrace in prc.options: 
      getFrameDecl(p)
      app(generatedProc, p.s(cpsLocals))
      var procname = CStringLit(p, generatedProc, prc.name.s)
      var filename = CStringLit(p, generatedProc, toFilename(prc.info))
      app(generatedProc, initFrame(p, procname, filename))
    else: 
      app(generatedProc, p.s(cpsLocals))
    if (optProfiler in prc.options) and (gCmd != cmdCompileToLLVM): 
      if gProcProfile >= 64 * 1024: 
        InternalError(prc.info, "too many procedures for profiling")
      discard cgsym(m, "profileData")
      appf(p.s(cpsLocals), "\tticks NIM_profilingStart;$n")
      if prc.loc.a < 0: 
        appf(m.s[cfsDebugInit], "\tprofileData[$1].procname = $2;$n", [
            toRope(gProcProfile), 
            makeCString(prc.name.s)])
        prc.loc.a = gProcProfile
        inc(gProcProfile)
      prepend(p.s(cpsInit), ropef("\tNIM_profilingStart = getticks();$n"))
    app(generatedProc, p.s(cpsInit))
    app(generatedProc, p.s(cpsStmts))
    if p.beforeRetNeeded: appf(generatedProc, "\tBeforeRet: ;$n")
    app(generatedProc, deinitGCFrame(p))
    if optStackTrace in prc.options: app(generatedProc, deinitFrame(p))
    if (optProfiler in prc.options) and (gCmd != cmdCompileToLLVM): 
      appf(generatedProc, 
        "\tprofileData[$1].total += elapsed(getticks(), NIM_profilingStart);$n", 
        [toRope(prc.loc.a)])
    app(generatedProc, returnStmt)
    appf(generatedProc, "}$N")
  app(m.s[cfsProcs], generatedProc)
  
proc genProcPrototype(m: BModule, sym: PSym) = 
  useHeader(m, sym)
  if lfNoDecl in sym.loc.Flags: return 
  if lfDynamicLib in sym.loc.Flags:
    if getModule(sym).id != m.module.id and
        not ContainsOrIncl(m.declaredThings, sym.id): 
      appf(m.s[cfsVars], "extern $1 $2;$n", 
           [getTypeDesc(m, sym.loc.t), mangleDynLibProc(sym)])
      if gCmd == cmdCompileToLLVM: incl(sym.loc.flags, lfIndirect)
  elif not ContainsOrIncl(m.declaredProtos, sym.id): 
    appf(m.s[cfsProcHeaders], "$1;$n", [genProcHeader(m, sym)])

proc genProcNoForward(m: BModule, prc: PSym) = 
  fillProcLoc(prc)
  useHeader(m, prc)
  if lfImportCompilerProc in prc.loc.flags:
    # dependency to a compilerproc:
    discard cgsym(m, prc.name.s)
    return  
  genProcPrototype(m, prc)  
  if lfNoDecl in prc.loc.Flags: nil
  elif prc.typ.callConv == ccInline:
    # We add inline procs to the calling module to enable C based inlining.
    # This also means that a check with ``q.declaredThings`` is wrong, we need
    # a check for ``m.declaredThings``.
    if not ContainsOrIncl(m.declaredThings, prc.id): genProcAux(m, prc)
  elif lfDynamicLib in prc.loc.flags:
    var q = findPendingModule(m, prc)
    if q != nil and not ContainsOrIncl(q.declaredThings, prc.id): 
      SymInDynamicLib(q, prc)
    else:
      SymInDynamicLibPartial(m, prc)
  elif sfImportc notin prc.flags:
    var q = findPendingModule(m, prc)
    if q != nil and not ContainsOrIncl(q.declaredThings, prc.id): 
      genProcAux(q, prc)

proc requestConstImpl(p: BProc, sym: PSym) =
  var m = p.module
  useHeader(m, sym)
  if sym.loc.k == locNone:
    fillLoc(sym.loc, locData, sym.typ, mangleName(sym), OnUnknown)
  if lfNoDecl in sym.loc.Flags: return
  # declare implementation:
  var q = findPendingModule(m, sym)
  if q != nil and not ContainsOrIncl(q.declaredThings, sym.id):
    assert q.initProc.module == q
    appf(q.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
        [getTypeDesc(q, sym.typ), sym.loc.r, genConstExpr(q.initProc, sym.ast)])
  # declare header:
  if q != m and not ContainsOrIncl(m.declaredThings, sym.id):
    assert(sym.loc.r != nil)
    appf(m.s[cfsData], "extern NIM_CONST $1 $2;$n",
        [getTypeDesc(m, sym.loc.t), sym.loc.r])

proc genProc(m: BModule, prc: PSym) = 
  if sfBorrow in prc.flags: return 
  fillProcLoc(prc)
  if {sfForward, sfFromGeneric} * prc.flags != {}: addForwardedProc(m, prc)
  else: genProcNoForward(m, prc)
  
proc genVarPrototype(m: BModule, sym: PSym) = 
  assert(sfGlobal in sym.flags)
  useHeader(m, sym)
  fillLoc(sym.loc, locGlobalVar, sym.typ, mangleName(sym), OnHeap)
  if (lfNoDecl in sym.loc.Flags) or ContainsOrIncl(m.declaredThings, sym.id): 
    return 
  if sym.owner.id != m.module.id: 
    # else we already have the symbol generated!
    assert(sym.loc.r != nil)
    if sfThread in sym.flags: 
      declareThreadVar(m, sym, true)
    else:
      app(m.s[cfsVars], "extern ")
      app(m.s[cfsVars], getTypeDesc(m, sym.loc.t))
      if lfDynamicLib in sym.loc.flags: app(m.s[cfsVars], "*")
      if sfRegister in sym.flags: app(m.s[cfsVars], " register")
      if sfVolatile in sym.flags: app(m.s[cfsVars], " volatile")
      appf(m.s[cfsVars], " $1;$n", [sym.loc.r])

proc getFileHeader(cfilenoext: string): PRope = 
  if optCompileOnly in gGlobalOptions: 
    result = ropeff("/* Generated by Nimrod Compiler v$1 */$n" &
        "/*   (c) 2012 Andreas Rumpf */$n", 
        "; Generated by Nimrod Compiler v$1$n" &
        ";   (c) 2012 Andreas Rumpf$n", [toRope(versionAsString)])
  else: 
    result = ropeff("/* Generated by Nimrod Compiler v$1 */$n" &
        "/*   (c) 2012 Andreas Rumpf */$n" & 
        "/* Compiled for: $2, $3, $4 */$n" &
        "/* Command for C compiler:$n   $5 */$n", 
        "; Generated by Nimrod Compiler v$1$n" &
        ";   (c) 2012 Andreas Rumpf$n" & 
        "; Compiled for: $2, $3, $4$n" &
        "; Command for LLVM compiler:$n   $5$n", [toRope(versionAsString), 
        toRope(platform.OS[targetOS].name), 
        toRope(platform.CPU[targetCPU].name), 
        toRope(extccomp.CC[extccomp.ccompiler].name), 
        toRope(getCompileCFileCmd(cfilenoext))])
  case platform.CPU[targetCPU].intSize
  of 16: 
    appff(result, 
          "$ntypedef short int NI;$n" & "typedef unsigned short int NU;$n", 
          "$n%NI = type i16$n", [])
  of 32: 
    appff(result, 
          "$ntypedef long int NI;$n" & "typedef unsigned long int NU;$n", 
          "$n%NI = type i32$n", [])
  of 64: 
    appff(result, "$ntypedef long long int NI;$n" &
        "typedef unsigned long long int NU;$n", "$n%NI = type i64$n", [])
  else: 
    nil

proc genMainProc(m: BModule) = 
  const 
    CommonMainBody =
        "\tsystemDatInit();$n" &
        "$1" &
        "$2" &
        "\tsystemInit();$n" &
        "$3" &
        "$4"
    PosixNimMain = 
        "int cmdCount;$n" & 
        "char** cmdLine;$n" & 
        "char** gEnv;$n" &
        "N_CDECL(void, NimMain)(void) {$n" &
        CommonMainBody & "}$n"
    PosixCMain = "int main(int argc, char** args, char** env) {$n" &
        "\tcmdLine = args;$n" & "\tcmdCount = argc;$n" & "\tgEnv = env;$n" &
        "\tNimMain();$n" & "\treturn nim_program_result;$n" & "}$n"
    StandaloneCMain = "int main(void) {$n" &
        "\tNimMain();$n" & 
        "\treturn 0;$n" & "}$n"
    WinNimMain = "N_CDECL(void, NimMain)(void) {$n" &
        CommonMainBody & "}$n"
    WinCMain = "N_STDCALL(int, WinMain)(HINSTANCE hCurInstance, $n" &
        "                        HINSTANCE hPrevInstance, $n" &
        "                        LPSTR lpCmdLine, int nCmdShow) {$n" &
        "\tNimMain();$n" & "\treturn nim_program_result;$n" & "}$n"
    WinNimDllMain = "N_LIB_EXPORT N_CDECL(void, NimMain)(void) {$n" &
        CommonMainBody & "}$n"
    WinCDllMain = 
        "BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdreason, $n" &
        "                    LPVOID lpvReserved) {$n" & "\tNimMain();$n" &
        "\treturn 1;$n" & "}$n"
    PosixNimDllMain = WinNimDllMain
    PosixCDllMain = 
        "void NIM_POSIX_INIT NimMainInit(void) {$n" &
        "\tNimMain();$n}$n"
  var nimMain, otherMain: TFormatStr
  if platform.targetOS == osWindows and
      gGlobalOptions * {optGenGuiApp, optGenDynLib} != {}: 
    if optGenGuiApp in gGlobalOptions: 
      nimMain = WinNimMain
      otherMain = WinCMain
    else: 
      nimMain = WinNimDllMain
      otherMain = WinCDllMain
    discard lists.IncludeStr(m.headerFiles, "<windows.h>")
  elif optGenDynLib in gGlobalOptions:
    nimMain = posixNimDllMain
    otherMain = posixCDllMain
  elif platform.targetOS == osStandalone:
    nimMain = PosixNimMain
    otherMain = StandaloneCMain
  else:
    nimMain = PosixNimMain
    otherMain = PosixCMain
  if gBreakpoints != nil: discard cgsym(m, "dbgRegisterBreakpoint")
  
  let initStackBottomCall = if emulatedThreadVars() or
                              platform.targetOS == osStandalone: "".toRope
                            else: ropecg(m, "\t#initStackBottom();$n")
  inc(m.labels)
  appcg(m, m.s[cfsProcs], nimMain, [mainDatInit, initStackBottomCall,
        gBreakpoints, mainModInit, toRope(m.labels)])
  if optNoMain notin gGlobalOptions:
    appcg(m, m.s[cfsProcs], otherMain, [])
  
proc getInitName(m: PSym): PRope = 
  result = ropeff("$1Init", "@$1Init", [toRope(m.name.s)])

proc getDatInitName(m: PSym): PRope =
  result = ropeff("$1DatInit", "@$1DatInit", [toRope(m.name.s)])

proc registerModuleToMain(m: PSym) = 
  var
    init = m.getInitName
    datInit = m.getDatInitName
  appff(mainModProcs, "N_NOINLINE(void, $1)(void);$N",
                      "declare void $1() noinline$N", [init])
  appff(mainModProcs, "N_NOINLINE(void, $1)(void);$N",
                      "declare void $1() noinline$N", [datInit])
  if not (sfSystemModule in m.flags):
    appff(mainModInit, "\t$1();$n", "call void ()* $1$n", [init])
    appff(mainDatInit, "\t$1();$n", "call void ()* $1$n", [datInit])
  
proc genInitCode(m: BModule) = 
  if optProfiler in m.initProc.options: 
    # This does not really belong here, but there is no good place for this
    # code. I don't want to put this to the proc generation as the
    # ``IncludeStr`` call is quite slow.
    discard lists.IncludeStr(m.headerFiles, "<cycle.h>")
  var initname = getInitName(m.module)
  var prc = ropeff("N_NOINLINE(void, $1)(void) {$n", 
                   "define void $1() noinline {$n", [initname])
  if m.typeNodes > 0: 
    appcg(m, m.s[cfsTypeInit1], "static #TNimNode $1[$2];$n", 
          [m.typeNodesName, toRope(m.typeNodes)])
  if m.nimTypes > 0: 
    appcg(m, m.s[cfsTypeInit1], "static #TNimType $1[$2];$n", 
          [m.nimTypesName, toRope(m.nimTypes)])
  if optStackTrace in m.initProc.options and not m.FrameDeclared:
    # BUT: the generated init code might depend on a current frame, so
    # declare it nevertheless:
    m.FrameDeclared = true
    getFrameDecl(m.initProc)
  
  app(prc, initGCFrame(m.initProc))
 
  app(prc, genSectionStart(cpsLocals))
  app(prc, m.initProc.s(cpsLocals))
  app(prc, m.preInitProc.s(cpsLocals))
  app(prc, genSectionEnd(cpsLocals))

  if optStackTrace in m.initProc.options and not m.PreventStackTrace: 
    var procname = CStringLit(m.initProc, prc, m.module.name.s)
    var filename = CStringLit(m.initProc, prc, toFilename(m.module.info))
    app(prc, initFrame(m.initProc, procname, filename))
 
  app(prc, genSectionStart(cpsInit))
  app(prc, m.preInitProc.s(cpsInit))
  app(prc, m.initProc.s(cpsInit))
  app(prc, genSectionEnd(cpsInit))

  app(prc, genSectionStart(cpsStmts))
  app(prc, m.preInitProc.s(cpsStmts))
  app(prc, m.initProc.s(cpsStmts))
  if optStackTrace in m.initProc.options and not m.PreventStackTrace:
    app(prc, deinitFrame(m.initProc))
  app(prc, genSectionEnd(cpsStmts))
  app(prc, deinitGCFrame(m.initProc))
  appf(prc, "}$N$N")

  prc.appff("N_NOINLINE(void, $1)(void) {$n",
            "define void $1() noinline {$n", [getDatInitName(m.module)])

  for i in cfsTypeInit1..cfsDynLibInit:
    app(prc, genSectionStart(i))
    app(prc, m.s[i])
    app(prc, genSectionEnd(i))
  
  appf(prc, "}$N$N")
  # we cannot simply add the init proc to ``m.s[cfsProcs]`` anymore because
  # that would lead to a *nesting* of merge sections which the merger does
  # not support. So we add it to another special section: ``cfsInitProc``
  app(m.s[cfsInitProc], prc)

proc genModule(m: BModule, cfilenoext: string): PRope = 
  result = getFileHeader(cfilenoext)
  result.app(genMergeInfo(m))
  
  generateHeaders(m)

  generateThreadLocalStorage(m)
  for i in countup(cfsHeaders, cfsProcs): 
    app(result, genSectionStart(i))
    app(result, m.s[i])
    app(result, genSectionEnd(i))
  app(result, m.s[cfsInitProc])
  
proc rawNewModule(module: PSym, filename: string): BModule = 
  new(result)
  InitLinkedList(result.headerFiles)
  result.declaredThings = initIntSet()
  result.declaredProtos = initIntSet()
  result.cfilename = filename
  result.filename = filename
  initIdTable(result.typeCache)
  initIdTable(result.forwTypeCache)
  result.module = module
  result.typeInfoMarker = initIntSet()
  result.initProc = newProc(nil, result)
  result.initProc.options = gOptions
  result.preInitProc = newProc(nil, result)
  initNodeTable(result.dataCache)
  result.typeStack = @[]
  result.forwardedProcs = @[]
  result.typeNodesName = getTempName()
  result.nimTypesName = getTempName()
  result.PreventStackTrace = sfSystemModule in module.flags

proc newModule(module: PSym, filename: string): BModule = 
  result = rawNewModule(module, filename)
  if gModules.len <= module.position: gModules.setLen(module.position + 1)
  gModules[module.position] = result

  if (optDeadCodeElim in gGlobalOptions): 
    if (sfDeadCodeElim in module.flags): 
      InternalError("added pending module twice: " & filename)
    addPendingModule(result)

proc myOpen(module: PSym, filename: string): PPassContext = 
  result = newModule(module, filename)

proc getCFile(m: BModule): string =
  result = changeFileExt(completeCFilePath(m.cfilename), cExt)

proc myOpenCached(module: PSym, filename: string, 
                  rd: PRodReader): PPassContext = 
  var m = newModule(module, filename)
  readMergeInfo(getCFile(m), m)
  result = m

proc myProcess(b: PPassContext, n: PNode): PNode = 
  result = n
  if b == nil or passes.skipCodegen(n): return
  var m = BModule(b)
  m.initProc.options = gOptions
  genStmts(m.initProc, n)

proc finishModule(m: BModule) = 
  var i = 0
  while i <= high(m.forwardedProcs): 
    # Note: ``genProc`` may add to ``m.forwardedProcs``, so we cannot use
    # a ``for`` loop here
    var prc = m.forwardedProcs[i]
    if sfForward in prc.flags: 
      InternalError(prc.info, "still forwarded: " & prc.name.s)
    genProcNoForward(m, prc)
    inc(i)
  assert(gForwardedProcsCounter >= i)
  dec(gForwardedProcsCounter, i)
  setlen(m.forwardedProcs, 0)

proc shouldRecompile(code: PRope, cfile, cfilenoext: string): bool = 
  result = true
  if optForceFullMake notin gGlobalOptions:
    var objFile = toObjFile(cfilenoext)
    if writeRopeIfNotEqual(code, cfile): return 
    if ExistsFile(objFile) and os.FileNewer(objFile, cfile): result = false
  else: 
    writeRope(code, cfile)

# We need 2 different logics here: pending modules (including
# 'nim__dat') may require file merging for the combination of dead code
# elimination and incremental compilation! Non pending modules need no
# such logic and in fact the logic hurts for the main module at least;
# it would generate multiple 'main' procs, for instance.

proc writeModule(m: BModule, pending: bool) =
  # generate code for the init statements of the module:
  var cfile = getCFile(m)
  var cfilenoext = changeFileExt(cfile, "")
  
  if not m.fromCache or optForceFullMake in gGlobalOptions:
    genInitCode(m)
    finishTypeDescriptions(m)
    if sfMainModule in m.module.flags: 
      # generate main file:
      app(m.s[cfsProcHeaders], mainModProcs)
      GenerateThreadVarsSize(m)
    
    var code = genModule(m, cfilenoext)
    when hasTinyCBackend:
      if gCmd == cmdRun:
        tccgen.compileCCode(ropeToStr(code))
        return

    if shouldRecompile(code, cfile, cfilenoext):
      addFileToCompile(cfilenoext)
  elif pending and mergeRequired(m) and sfMainModule notin m.module.flags:
    mergeFiles(cfile, m)
    genInitCode(m)
    finishTypeDescriptions(m)
    var code = genModule(m, cfilenoext)
    writeRope(code, cfile)
    addFileToCompile(cfilenoext)
  elif not ExistsFile(toObjFile(cfilenoext)):
    # Consider: first compilation compiles ``system.nim`` and produces
    # ``system.c`` but then compilation fails due to an error. This means
    # that ``system.o`` is missing, so we need to call the C compiler for it:
    addFileToCompile(cfilenoext)
  addFileToLink(cfilenoext)

proc myClose(b: PPassContext, n: PNode): PNode = 
  result = n
  if b == nil or passes.skipCodegen(n): return 
  var m = BModule(b)
  if n != nil: 
    m.initProc.options = gOptions
    genStmts(m.initProc, n)
  # cached modules need to registered too: 
  registerModuleToMain(m.module)
  
  if sfMainModule in m.module.flags: 
    var disp = generateMethodDispatchers()
    for i in 0..sonsLen(disp)-1: genProcAux(m, disp.sons[i].sym)
    genMainProc(m) 
    # we need to process the transitive closure because recursive module
    # deps are allowed (and the system module is processed in the wrong
    # order anyway)
    while gForwardedProcsCounter > 0: 
      for i in countup(0, high(gModules)): 
        finishModule(gModules[i])
    for i in countup(0, high(gModules)): 
      writeModule(gModules[i], pending=true)
    writeMapping(gMapping)

proc cgenPass(): TPass = 
  initPass(result)
  result.open = myOpen
  result.openCached = myOpenCached
  result.process = myProcess
  result.close = myClose

