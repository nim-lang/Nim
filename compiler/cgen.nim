#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the C code generator.

import
  ast, astalgo, hashes, trees, platform, magicsys, extccomp, options, intsets,
  nversion, nimsets, msgs, std / sha1, bitsets, idents, types,
  ccgutils, os, ropes, math, passes, wordrecg, treetab, cgmeth,
  condsyms, rodutils, renderer, idgen, cgendata, ccgmerge, semfold, aliases,
  lowerings, tables, sets, ndi, lineinfos, pathutils, transf

when not defined(leanCompiler):
  import semparallel

import strutils except `%` # collides with ropes.`%`

from modulegraphs import ModuleGraph, PPassContext
from lineinfos import
  warnGcMem, errXMustBeCompileTime, hintDependency, errGenerated, errCannotOpenFile
import dynlib

when not declared(dynlib.libCandidates):
  proc libCandidates(s: string, dest: var seq[string]) =
    ## given a library name pattern `s` write possible library names to `dest`.
    var le = strutils.find(s, '(')
    var ri = strutils.find(s, ')', le+1)
    if le >= 0 and ri > le:
      var prefix = substr(s, 0, le - 1)
      var suffix = substr(s, ri + 1)
      for middle in split(substr(s, le + 1, ri - 1), '|'):
        libCandidates(prefix & middle & suffix, dest)
    else:
      add(dest, s)

when options.hasTinyCBackend:
  import tccgen

proc hcrOn(m: BModule): bool = m.config.hcrOn
proc hcrOn(p: BProc): bool = p.module.config.hcrOn

proc addForwardedProc(m: BModule, prc: PSym) =
  m.g.forwardedProcs.add(prc)

proc findPendingModule(m: BModule, s: PSym): BModule =
  var ms = getModule(s)
  result = m.g.modules[ms.position]

proc initLoc(result: var TLoc, k: TLocKind, lode: PNode, s: TStorageLoc) =
  result.k = k
  result.storage = s
  result.lode = lode
  result.r = nil
  result.flags = {}

proc fillLoc(a: var TLoc, k: TLocKind, lode: PNode, r: Rope, s: TStorageLoc) =
  # fills the loc if it is not already initialized
  if a.k == locNone:
    a.k = k
    a.lode = lode
    a.storage = s
    if a.r == nil: a.r = r

proc t(a: TLoc): PType {.inline.} =
  if a.lode.kind == nkSym:
    result = a.lode.sym.typ
  else:
    result = a.lode.typ

proc lodeTyp(t: PType): PNode =
  result = newNode(nkEmpty)
  result.typ = t

proc isSimpleConst(typ: PType): bool =
  let t = skipTypes(typ, abstractVar)
  result = t.kind notin
      {tyTuple, tyObject, tyArray, tySet, tySequence} and not
      (t.kind == tyProc and t.callConv == ccClosure)

proc useHeader(m: BModule, sym: PSym) =
  if lfHeader in sym.loc.flags:
    assert(sym.annex != nil)
    let str = getStr(sym.annex.path)
    m.includeHeader(str)

proc cgsym(m: BModule, name: string): Rope

proc getCFile(m: BModule): AbsoluteFile

proc getModuleDllPath(m: BModule): Rope =
  let (dir, name, ext) = splitFile(getCFile(m))
  let filename = strutils.`%`(platform.OS[m.g.config.target.targetOS].dllFrmt, [name & ext])
  return makeCString(dir.string & "/" & filename)

proc getModuleDllPath(m: BModule, s: PSym): Rope =
  return getModuleDllPath(findPendingModule(m, s))

# TODO: please document
proc ropecg(m: BModule, frmt: FormatStr, args: varargs[Rope]): Rope =
  assert m != nil
  var i = 0
  var length = len(frmt)
  result = nil
  var num = 0
  while i < length:
    if frmt[i] == '$':
      inc(i)                  # skip '$'
      case frmt[i]
      of '$':
        add(result, "$")
        inc(i)
      of '#':
        inc(i)
        add(result, args[num])
        inc(num)
      of '0'..'9':
        var j = 0
        while true:
          j = (j * 10) + ord(frmt[i]) - ord('0')
          inc(i)
          if i >= length or not (frmt[i] in {'0'..'9'}): break
        num = j
        if j > high(args) + 1:
          internalError(m.config, "ropes: invalid format string $" & $j)
        add(result, args[j-1])
      of 'n':
        if optLineDir notin m.config.options: add(result, "\L")
        inc(i)
      of 'N':
        add(result, "\L")
        inc(i)
      else: internalError(m.config, "ropes: invalid format string $" & frmt[i])
    elif frmt[i] == '#' and frmt[i+1] in IdentStartChars:
      inc(i)
      var j = i
      while frmt[j] in IdentChars: inc(j)
      var ident = substr(frmt, i, j-1)
      i = j
      add(result, cgsym(m, ident))
    elif frmt[i] == '#' and frmt[i+1] == '$':
      inc(i, 2)
      var j = 0
      while frmt[i] in Digits:
        j = (j * 10) + ord(frmt[i]) - ord('0')
        inc(i)
      add(result, cgsym(m, $args[j-1]))
    var start = i
    while i < length:
      if frmt[i] != '$' and frmt[i] != '#': inc(i)
      else: break
    if i - 1 >= start:
      add(result, substr(frmt, start, i - 1))

proc indentLine(p: BProc, r: Rope): Rope =
  result = r
  for i in countup(0, p.blocks.len-1):
    prepend(result, "\t".rope)

proc appcg(m: BModule, c: var Rope, frmt: FormatStr,
           args: varargs[Rope]) =
  add(c, ropecg(m, frmt, args))

proc appcg(m: BModule, s: TCFileSection, frmt: FormatStr,
           args: varargs[Rope]) =
  add(m.s[s], ropecg(m, frmt, args))

proc appcg(p: BProc, s: TCProcSection, frmt: FormatStr,
           args: varargs[Rope]) =
  add(p.s(s), ropecg(p.module, frmt, args))

proc line(p: BProc, s: TCProcSection, r: Rope) =
  add(p.s(s), indentLine(p, r))

proc line(p: BProc, s: TCProcSection, r: string) =
  add(p.s(s), indentLine(p, r.rope))

proc lineF(p: BProc, s: TCProcSection, frmt: FormatStr,
              args: openarray[Rope]) =
  add(p.s(s), indentLine(p, frmt % args))

proc lineCg(p: BProc, s: TCProcSection, frmt: FormatStr,
               args: varargs[Rope]) =
  add(p.s(s), indentLine(p, ropecg(p.module, frmt, args)))

proc linefmt(p: BProc, s: TCProcSection, frmt: FormatStr,
             args: varargs[Rope]) =
  add(p.s(s), indentLine(p, ropecg(p.module, frmt, args)))

proc safeLineNm(info: TLineInfo): int =
  result = toLinenumber(info)
  if result < 0: result = 0 # negative numbers are not allowed in #line

proc genCLineDir(r: var Rope, filename: string, line: int; conf: ConfigRef) =
  assert line >= 0
  if optLineDir in conf.options:
    addf(r, "$N#line $2 $1$N",
        [rope(makeSingleLineCString(filename)), rope(line)])

proc genCLineDir(r: var Rope, info: TLineInfo; conf: ConfigRef) =
  genCLineDir(r, toFullPath(conf, info), info.safeLineNm, conf)

proc freshLineInfo(p: BProc; info: TLineInfo): bool =
  if p.lastLineInfo.line != info.line or
     p.lastLineInfo.fileIndex != info.fileIndex:
    p.lastLineInfo.line = info.line
    p.lastLineInfo.fileIndex = info.fileIndex
    result = true

proc genLineDir(p: BProc, t: PNode) =
  let line = t.info.safeLineNm

  if optEmbedOrigSrc in p.config.globalOptions:
    add(p.s(cpsStmts), ~"//" & sourceLine(p.config, t.info) & "\L")
  genCLineDir(p.s(cpsStmts), toFullPath(p.config, t.info), line, p.config)
  if ({optStackTrace, optEndb} * p.options == {optStackTrace, optEndb}) and
      (p.prc == nil or sfPure notin p.prc.flags):
    if freshLineInfo(p, t.info):
      linefmt(p, cpsStmts, "#endb($1, $2);$N",
              line.rope, makeCString(toFilename(p.config, t.info)))
  elif ({optLineTrace, optStackTrace} * p.options ==
      {optLineTrace, optStackTrace}) and
      (p.prc == nil or sfPure notin p.prc.flags) and t.info.fileIndex != InvalidFileIDX:
    if freshLineInfo(p, t.info):
      linefmt(p, cpsStmts, "nimln_($1, $2);$n",
              line.rope, quotedFilename(p.config, t.info))

proc postStmtActions(p: BProc) {.inline.} =
  add(p.s(cpsStmts), p.module.injectStmt)

proc accessThreadLocalVar(p: BProc, s: PSym)
proc emulatedThreadVars(conf: ConfigRef): bool {.inline.}
proc genProc(m: BModule, prc: PSym)

template compileToCpp(m: BModule): untyped =
  m.config.cmd == cmdCompileToCpp or sfCompileToCpp in m.module.flags

proc getTempName(m: BModule): Rope =
  result = m.tmpBase & rope(m.labels)
  inc m.labels

proc rdLoc(a: TLoc): Rope =
  # 'read' location (deref if indirect)
  result = a.r
  if lfIndirect in a.flags: result = "(*$1)" % [result]

proc lenField(p: BProc): Rope =
  result = rope(if p.module.compileToCpp: "len" else: "Sup.len")

proc lenExpr(p: BProc; a: TLoc): Rope =
  if p.config.selectedGc == gcDestructors:
    result = rdLoc(a) & ".len"
  else:
    result = "($1 ? $1->$2 : 0)" % [rdLoc(a), lenField(p)]

proc dataField(p: BProc): Rope =
  if p.config.selectedGc == gcDestructors:
    result = rope".p->data"
  else:
    result = rope"->data"

include ccgliterals
include ccgtypes

# ------------------------------ Manager of temporaries ------------------

proc addrLoc(conf: ConfigRef; a: TLoc): Rope =
  result = a.r
  if lfIndirect notin a.flags and mapType(conf, a.t) != ctArray:
    result = "(&" & result & ")"

proc byRefLoc(p: BProc; a: TLoc): Rope =
  result = a.r
  if lfIndirect notin a.flags and mapType(p.config, a.t) != ctArray and not
      p.module.compileToCpp:
    result = "(&" & result & ")"

proc rdCharLoc(a: TLoc): Rope =
  # read a location that may need a char-cast:
  result = rdLoc(a)
  if skipTypes(a.t, abstractRange).kind == tyChar:
    result = "((NU8)($1))" % [result]

proc genObjectInit(p: BProc, section: TCProcSection, t: PType, a: TLoc,
                   takeAddr: bool) =
  if p.module.compileToCpp and t.isException and not isDefined(p.config, "noCppExceptions"):
    # init vtable in Exception object for polymorphic exceptions
    includeHeader(p.module, "<new>")
    linefmt(p, section, "new ($1) $2;$n", rdLoc(a), getTypeDesc(p.module, t))

  #if optNimV2 in p.config.globalOptions: return
  case analyseObjectWithTypeField(t)
  of frNone:
    discard
  of frHeader:
    var r = rdLoc(a)
    if not takeAddr: r = "(*$1)" % [r]
    var s = skipTypes(t, abstractInst)
    if not p.module.compileToCpp:
      while s.kind == tyObject and s.sons[0] != nil:
        add(r, ".Sup")
        s = skipTypes(s.sons[0], skipPtrs)
    linefmt(p, section, "$1.m_type = $2;$n", r, genTypeInfo(p.module, t, a.lode.info))
  of frEmbedded:
    # worst case for performance:
    var r = if takeAddr: addrLoc(p.config, a) else: rdLoc(a)
    linefmt(p, section, "#objectInit($1, $2);$n", r, genTypeInfo(p.module, t, a.lode.info))

type
  TAssignmentFlag = enum
    needToCopy
  TAssignmentFlags = set[TAssignmentFlag]

proc genRefAssign(p: BProc, dest, src: TLoc)

proc isComplexValueType(t: PType): bool {.inline.} =
  let t = t.skipTypes(abstractInst + tyUserTypeClasses)
  result = t.kind in {tyArray, tySet, tyTuple, tyObject} or
    (t.kind == tyProc and t.callConv == ccClosure)

proc resetLoc(p: BProc, loc: var TLoc) =
  let containsGcRef = p.config.selectedGc != gcDestructors and containsGarbageCollectedRef(loc.t)
  let typ = skipTypes(loc.t, abstractVarRange)
  if isImportedCppType(typ): return
  if p.config.selectedGc == gcDestructors and typ.kind in {tyString, tySequence}:
    assert rdLoc(loc) != nil
    linefmt(p, cpsStmts, "$1.len = 0; $1.p = NIM_NIL;$n", rdLoc(loc))
  elif not isComplexValueType(typ):
    if containsGcRef:
      var nilLoc: TLoc
      initLoc(nilLoc, locTemp, loc.lode, OnStack)
      nilLoc.r = rope("NIM_NIL")
      genRefAssign(p, loc, nilLoc)
    else:
      linefmt(p, cpsStmts, "$1 = 0;$n", rdLoc(loc))
  else:
    if optNilCheck in p.options:
      linefmt(p, cpsStmts, "#chckNil((void*)$1);$n", addrLoc(p.config, loc))
    if loc.storage != OnStack and containsGcRef:
      linefmt(p, cpsStmts, "#genericReset((void*)$1, $2);$n",
              addrLoc(p.config, loc), genTypeInfo(p.module, loc.t, loc.lode.info))
      # XXX: generated reset procs should not touch the m_type
      # field, so disabling this should be safe:
      genObjectInit(p, cpsStmts, loc.t, loc, true)
    else:
      # array passed as argument decayed into pointer, bug #7332
      # so we use getTypeDesc here rather than rdLoc(loc)
      linefmt(p, cpsStmts, "#nimZeroMem((void*)$1, sizeof($2));$n",
              addrLoc(p.config, loc), getTypeDesc(p.module, loc.t))
      # XXX: We can be extra clever here and call memset only
      # on the bytes following the m_type field?
      genObjectInit(p, cpsStmts, loc.t, loc, true)

proc constructLoc(p: BProc, loc: TLoc, isTemp = false) =
  let typ = loc.t
  if p.config.selectedGc == gcDestructors and skipTypes(typ, abstractInst).kind in {tyString, tySequence}:
    linefmt(p, cpsStmts, "$1.len = 0; $1.p = NIM_NIL;$n", rdLoc(loc))
  elif not isComplexValueType(typ):
    linefmt(p, cpsStmts, "$1 = ($2)0;$n", rdLoc(loc),
      getTypeDesc(p.module, typ))
  else:
    if not isTemp or containsGarbageCollectedRef(loc.t):
      # don't use nimZeroMem for temporary values for performance if we can
      # avoid it:
      if not isImportedCppType(typ):
        linefmt(p, cpsStmts, "#nimZeroMem((void*)$1, sizeof($2));$n",
                addrLoc(p.config, loc), getTypeDesc(p.module, typ))
    genObjectInit(p, cpsStmts, loc.t, loc, true)

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

proc getTemp(p: BProc, t: PType, result: var TLoc; needsInit=false) =
  inc(p.labels)
  result.r = "T" & rope(p.labels) & "_"
  linefmt(p, cpsLocals, "$1 $2;$n", getTypeDesc(p.module, t), result.r)
  result.k = locTemp
  result.lode = lodeTyp t
  result.storage = OnStack
  result.flags = {}
  constructLoc(p, result, not needsInit)

proc getIntTemp(p: BProc, result: var TLoc) =
  inc(p.labels)
  result.r = "T" & rope(p.labels) & "_"
  linefmt(p, cpsLocals, "NI $1;$n", result.r)
  result.k = locTemp
  result.storage = OnStack
  result.lode = lodeTyp getSysType(p.module.g.graph, unknownLineInfo(), tyInt)
  result.flags = {}

proc initGCFrame(p: BProc): Rope =
  if p.gcFrameId > 0: result = "struct {$1} GCFRAME_;$n" % [p.gcFrameType]

proc deinitGCFrame(p: BProc): Rope =
  if p.gcFrameId > 0:
    result = ropecg(p.module,
                    "if (((NU)&GCFRAME_) < 4096) #nimGCFrame(&GCFRAME_);$n")

proc localDebugInfo(p: BProc, s: PSym, retType: PType) =
  if {optStackTrace, optEndb} * p.options != {optStackTrace, optEndb}: return
  # XXX work around a bug: No type information for open arrays possible:
  if skipTypes(s.typ, abstractVar).kind in {tyOpenArray, tyVarargs}: return
  var a = "&" & s.loc.r
  if s.kind == skParam and ccgIntroducedPtr(p.config, s, retType): a = s.loc.r
  lineF(p, cpsInit,
       "FR_.s[$1].address = (void*)$3; FR_.s[$1].typ = $4; FR_.s[$1].name = $2;$n",
       [p.maxFrameLen.rope, makeCString(normalize(s.name.s)), a,
        genTypeInfo(p.module, s.loc.t, s.info)])
  inc(p.maxFrameLen)
  inc p.blocks[p.blocks.len-1].frameLen

proc localVarDecl(p: BProc; n: PNode): Rope =
  let s = n.sym
  if s.loc.k == locNone:
    fillLoc(s.loc, locLocalVar, n, mangleLocalName(p, s), OnStack)
    if s.kind == skLet: incl(s.loc.flags, lfNoDeepCopy)
  result = getTypeDesc(p.module, s.typ)
  if s.constraint.isNil:
    if sfRegister in s.flags: add(result, " register")
    #elif skipTypes(s.typ, abstractInst).kind in GcTypeKinds:
    #  add(decl, " GC_GUARD")
    if sfVolatile in s.flags: add(result, " volatile")
    add(result, " ")
    add(result, s.loc.r)
  else:
    result = s.cgDeclFrmt % [result, s.loc.r]

proc assignLocalVar(p: BProc, n: PNode) =
  #assert(s.loc.k == locNone) # not yet assigned
  # this need not be fulfilled for inline procs; they are regenerated
  # for each module that uses them!
  let nl = if optLineDir in p.config.options: "" else: "\L"
  let decl = localVarDecl(p, n) & ";" & nl
  line(p, cpsLocals, decl)
  localDebugInfo(p, n.sym, nil)

include ccgthreadvars

proc varInDynamicLib(m: BModule, sym: PSym)

proc treatGlobalDifferentlyForHCR(m: BModule, s: PSym): bool =
  return m.hcrOn and {sfThread, sfGlobal} * s.flags == {sfGlobal} and
      ({lfNoDecl, lfHeader} * s.loc.flags == {})
      # and s.owner.kind == skModule # owner isn't always a module (global pragma on local var)
      # and s.loc.k == locGlobalVar  # loc isn't always initialized when this proc is used

proc assignGlobalVar(p: BProc, n: PNode) =
  let s = n.sym
  if s.loc.k == locNone:
    fillLoc(s.loc, locGlobalVar, n, mangleName(p.module, s), OnHeap)
    if treatGlobalDifferentlyForHCR(p.module, s): incl(s.loc.flags, lfIndirect)

  if lfDynamicLib in s.loc.flags:
    var q = findPendingModule(p.module, s)
    if q != nil and not containsOrIncl(q.declaredThings, s.id):
      varInDynamicLib(q, s)
    else:
      s.loc.r = mangleDynLibProc(s)
    return
  useHeader(p.module, s)
  if lfNoDecl in s.loc.flags: return
  if not containsOrIncl(p.module.declaredThings, s.id):
    if sfThread in s.flags:
      declareThreadVar(p.module, s, sfImportc in s.flags)
    else:
      var decl: Rope = nil
      var td = getTypeDesc(p.module, s.loc.t)
      if s.constraint.isNil:
        if p.hcrOn: add(decl, "static ")
        elif sfImportc in s.flags: add(decl, "extern ")
        add(decl, td)
        if p.hcrOn: add(decl, "*")
        if sfRegister in s.flags: add(decl, " register")
        if sfVolatile in s.flags: add(decl, " volatile")
        addf(decl, " $1;$n", [s.loc.r])
      else:
        decl = (s.cgDeclFrmt & ";$n") % [td, s.loc.r]
      add(p.module.s[cfsVars], decl)
  if p.withinLoop > 0:
    # fixes tests/run/tzeroarray:
    resetLoc(p, s.loc)
  if p.module.module.options * {optStackTrace, optEndb} ==
                               {optStackTrace, optEndb}:
    appcg(p.module, p.module.s[cfsDebugInit],
          "#dbgRegisterGlobal($1, &$2, $3);$n",
         [makeCString(normalize(s.owner.name.s & '.' & s.name.s)),
          s.loc.r, genTypeInfo(p.module, s.typ, n.info)])

proc assignParam(p: BProc, s: PSym, retType: PType) =
  assert(s.loc.r != nil)
  scopeMangledParam(p, s)
  localDebugInfo(p, s, retType)

proc fillProcLoc(m: BModule; n: PNode) =
  let sym = n.sym
  if sym.loc.k == locNone:
    fillLoc(sym.loc, locProc, n, mangleName(m, sym), OnStack)

proc getLabel(p: BProc): TLabel =
  inc(p.labels)
  result = "LA" & rope(p.labels) & "_"

proc fixLabel(p: BProc, labl: TLabel) =
  lineF(p, cpsStmts, "$1: ;$n", [labl])

proc genVarPrototype(m: BModule, n: PNode)
proc requestConstImpl(p: BProc, sym: PSym)
proc genStmts(p: BProc, t: PNode)
proc expr(p: BProc, n: PNode, d: var TLoc)
proc genProcPrototype(m: BModule, sym: PSym)
proc putLocIntoDest(p: BProc, d: var TLoc, s: TLoc)
proc genAssignment(p: BProc, dest, src: TLoc, flags: TAssignmentFlags)
proc intLiteral(i: BiggestInt): Rope
proc genLiteral(p: BProc, n: PNode): Rope
proc genOtherArg(p: BProc; ri: PNode; i: int; typ: PType): Rope

proc initLocExpr(p: BProc, e: PNode, result: var TLoc) =
  initLoc(result, locNone, e, OnUnknown)
  expr(p, e, result)

proc initLocExprSingleUse(p: BProc, e: PNode, result: var TLoc) =
  initLoc(result, locNone, e, OnUnknown)
  if e.kind in nkCallKinds and (e[0].kind != nkSym or e[0].sym.magic == mNone):
    # We cannot check for tfNoSideEffect here because of mutable parameters.
    discard "bug #8202; enforce evaluation order for nested calls for C++ too"
    # We may need to consider that 'f(g())' cannot be rewritten to 'tmp = g(); f(tmp)'
    # if 'tmp' lacks a move/assignment operator.
    if e[0].kind == nkSym and sfCompileToCpp in e[0].sym.flags:
      result.flags.incl lfSingleUse
  else:
    result.flags.incl lfSingleUse
  expr(p, e, result)

include ccgcalls, "ccgstmts.nim"

proc initFrame(p: BProc, procname, filename: Rope): Rope =
  const frameDefines = """
  $1  define nimfr_(proc, file) \
      TFrame FR_; \
      FR_.procname = proc; FR_.filename = file; FR_.line = 0; FR_.len = 0; #nimFrame(&FR_);

  $1  define nimfrs_(proc, file, slots, length) \
      struct {TFrame* prev;NCSTRING procname;NI line;NCSTRING filename; NI len; VarSlot s[slots];} FR_; \
      FR_.procname = proc; FR_.filename = file; FR_.line = 0; FR_.len = length; #nimFrame((TFrame*)&FR_);

  $1  define nimln_(n, file) \
      FR_.line = n; FR_.filename = file;
  """
  if p.module.s[cfsFrameDefines].len == 0:
    appcg(p.module, p.module.s[cfsFrameDefines], frameDefines, [rope("#")])

  discard cgsym(p.module, "nimFrame")
  if p.maxFrameLen > 0:
    discard cgsym(p.module, "VarSlot")
    result = ropecg(p.module, "\tnimfrs_($1, $2, $3, $4);$n",
                  procname, filename, p.maxFrameLen.rope,
                  p.blocks[0].frameLen.rope)
  else:
    result = ropecg(p.module, "\tnimfr_($1, $2);$n", procname, filename)

proc initFrameNoDebug(p: BProc; frame, procname, filename: Rope; line: int): Rope =
  discard cgsym(p.module, "nimFrame")
  addf(p.blocks[0].sections[cpsLocals], "TFrame $1;$n", [frame])
  result = ropecg(p.module, "\t$1.procname = $2; $1.filename = $3; " &
                      " $1.line = $4; $1.len = -1; nimFrame(&$1);$n",
                      frame, procname, filename, rope(line))

proc deinitFrameNoDebug(p: BProc; frame: Rope): Rope =
  result = ropecg(p.module, "\t#popFrameOfAddr(&$1);$n", frame)

proc deinitFrame(p: BProc): Rope =
  result = ropecg(p.module, "\t#popFrame();$n")

include ccgexprs

# ----------------------------- dynamic library handling -----------------
# We don't finalize dynamic libs as the OS does this for us.

proc isGetProcAddr(lib: PLib): bool =
  let n = lib.path
  result = n.kind in nkCallKinds and n.typ != nil and
    n.typ.kind in {tyPointer, tyProc}

proc loadDynamicLib(m: BModule, lib: PLib) =
  assert(lib != nil)
  if not lib.generated:
    lib.generated = true
    var tmp = getTempName(m)
    assert(lib.name == nil)
    lib.name = tmp # BUGFIX: cgsym has awful side-effects
    addf(m.s[cfsVars], "static void* $1;$n", [tmp])
    if lib.path.kind in {nkStrLit..nkTripleStrLit}:
      var s: TStringSeq = @[]
      libCandidates(lib.path.strVal, s)
      rawMessage(m.config, hintDependency, lib.path.strVal)
      var loadlib: Rope = nil
      for i in countup(0, high(s)):
        inc(m.labels)
        if i > 0: add(loadlib, "||")
        let n = newStrNode(nkStrLit, s[i])
        n.info = lib.path.info
        appcg(m, loadlib, "($1 = #nimLoadLibrary($2))$n",
              [tmp, genStringLiteral(m, n)])
      appcg(m, m.s[cfsDynLibInit],
            "if (!($1)) #nimLoadLibraryError($2);$n",
            [loadlib, genStringLiteral(m, lib.path)])
    else:
      var p = newProc(nil, m)
      p.options = p.options - {optStackTrace, optEndb}
      var dest: TLoc
      initLoc(dest, locTemp, lib.path, OnStack)
      dest.r = getTempName(m)
      appcg(m, m.s[cfsDynLibInit],"$1 $2;$n",
           [getTypeDesc(m, lib.path.typ), rdLoc(dest)])
      expr(p, lib.path, dest)

      add(m.s[cfsVars], p.s(cpsLocals))
      add(m.s[cfsDynLibInit], p.s(cpsInit))
      add(m.s[cfsDynLibInit], p.s(cpsStmts))
      appcg(m, m.s[cfsDynLibInit],
           "if (!($1 = #nimLoadLibrary($2))) #nimLoadLibraryError($2);$n",
           [tmp, rdLoc(dest)])

  if lib.name == nil: internalError(m.config, "loadDynamicLib")

proc mangleDynLibProc(sym: PSym): Rope =
  # we have to build this as a single rope in order not to trip the
  # optimization in genInfixCall
  if sfCompilerProc in sym.flags:
    # NOTE: sym.loc.r is the external name!
    result = rope(sym.name.s)
  else:
    result = rope(strutils.`%`("Dl_$1_", $sym.id))

proc symInDynamicLib(m: BModule, sym: PSym) =
  var lib = sym.annex
  let isCall = isGetProcAddr(lib)
  var extname = sym.loc.r
  if not isCall: loadDynamicLib(m, lib)
  var tmp = mangleDynLibProc(sym)
  sym.loc.r = tmp             # from now on we only need the internal name
  sym.typ.sym = nil           # generate a new name
  inc(m.labels, 2)
  if isCall:
    let n = lib.path
    var a: TLoc
    initLocExpr(m.initProc, n[0], a)
    var params = rdLoc(a) & "("
    for i in 1 .. n.len-2:
      initLocExpr(m.initProc, n[i], a)
      params.add(rdLoc(a))
      params.add(", ")
    let load = "\t$1 = ($2) ($3$4));$n" %
        [tmp, getTypeDesc(m, sym.typ), params, makeCString($extname)]
    var last = lastSon(n)
    if last.kind == nkHiddenStdConv: last = last.sons[1]
    internalAssert(m.config, last.kind == nkStrLit)
    let idx = last.strVal
    if idx.len == 0:
      add(m.initProc.s(cpsStmts), load)
    elif idx.len == 1 and idx[0] in {'0'..'9'}:
      add(m.extensionLoaders[idx[0]], load)
    else:
      internalError(m.config, sym.info, "wrong index: " & idx)
  else:
    appcg(m, m.s[cfsDynLibInit],
        "\t$1 = ($2) #nimGetProcAddr($3, $4);$n",
        [tmp, getTypeDesc(m, sym.typ), lib.name, makeCString($extname)])
  addf(m.s[cfsVars], "$2 $1;$n", [sym.loc.r, getTypeDesc(m, sym.loc.t)])

proc varInDynamicLib(m: BModule, sym: PSym) =
  var lib = sym.annex
  var extname = sym.loc.r
  loadDynamicLib(m, lib)
  incl(sym.loc.flags, lfIndirect)
  var tmp = mangleDynLibProc(sym)
  sym.loc.r = tmp             # from now on we only need the internal name
  inc(m.labels, 2)
  appcg(m, m.s[cfsDynLibInit],
      "$1 = ($2*) #nimGetProcAddr($3, $4);$n",
      [tmp, getTypeDesc(m, sym.typ), lib.name, makeCString($extname)])
  addf(m.s[cfsVars], "$2* $1;$n",
      [sym.loc.r, getTypeDesc(m, sym.loc.t)])

proc symInDynamicLibPartial(m: BModule, sym: PSym) =
  sym.loc.r = mangleDynLibProc(sym)
  sym.typ.sym = nil           # generate a new name

proc cgsym(m: BModule, name: string): Rope =
  let sym = magicsys.getCompilerProc(m.g.graph, name)
  if sym != nil:
    case sym.kind
    of skProc, skFunc, skMethod, skConverter, skIterator: genProc(m, sym)
    of skVar, skResult, skLet: genVarPrototype(m, newSymNode sym)
    of skType: discard getTypeDesc(m, sym.typ)
    else: internalError(m.config, "cgsym: " & name & ": " & $sym.kind)
  else:
    # we used to exclude the system module from this check, but for DLL
    # generation support this sloppyness leads to hard to detect bugs, so
    # we're picky here for the system module too:
    rawMessage(m.config, errGenerated, "system module needs: " & name)
  result = sym.loc.r
  if m.hcrOn and sym != nil and sym.kind in skProc..skIterator:
    result.addActualPrefixForHCR(m.module, sym)

proc generateHeaders(m: BModule) =
  add(m.s[cfsHeaders], "\L#include \"nimbase.h\"\L")

  for it in m.headerFiles:
    if it[0] == '#':
      add(m.s[cfsHeaders], rope(it.replace('`', '"') & "\L"))
    elif it[0] notin {'"', '<'}:
      addf(m.s[cfsHeaders], "#include \"$1\"$N", [rope(it)])
    else:
      addf(m.s[cfsHeaders], "#include $1$N", [rope(it)])
  add(m.s[cfsHeaders], """#undef LANGUAGE_C
#undef MIPSEB
#undef MIPSEL
#undef PPC
#undef R3000
#undef R4000
#undef i386
#undef linux
#undef mips
#undef near
#undef far
#undef powerpc
#undef unix
""")

proc openNamespaceNim(namespace: string): Rope =
  result.add("namespace ")
  result.add(namespace)
  result.add(" {\L")

proc closeNamespaceNim(): Rope =
  result.add("}\L")

proc closureSetup(p: BProc, prc: PSym) =
  if tfCapturesEnv notin prc.typ.flags: return
  # prc.ast[paramsPos].last contains the type we're after:
  var ls = lastSon(prc.ast[paramsPos])
  if ls.kind != nkSym:
    internalError(p.config, prc.info, "closure generation failed")
  var env = ls.sym
  #echo "created environment: ", env.id, " for ", prc.name.s
  assignLocalVar(p, ls)
  # generate cast assignment:
  if p.config.selectedGC == gcGo:
    linefmt(p, cpsStmts, "#unsureAsgnRef((void**) $1, ($2) ClE_0);$n",
            addrLoc(p.config, env.loc), getTypeDesc(p.module, env.typ))
  else:
    linefmt(p, cpsStmts, "$1 = ($2) ClE_0;$n",
            rdLoc(env.loc), getTypeDesc(p.module, env.typ))

proc containsResult(n: PNode): bool =
  if n.kind == nkSym and n.sym.kind == skResult:
    result = true
  else:
    for i in 0..<n.safeLen:
      if containsResult(n[i]): return true

const harmless = {nkConstSection, nkTypeSection, nkEmpty, nkCommentStmt, nkTemplateDef, nkMacroDef} +
                  declarativeDefs

proc easyResultAsgn(n: PNode): PNode =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    var i = 0
    while i < n.len and n[i].kind in harmless: inc i
    if i < n.len: result = easyResultAsgn(n[i])
  of nkAsgn, nkFastAsgn:
    if n[0].kind == nkSym and n[0].sym.kind == skResult and not containsResult(n[1]):
      incl n.flags, nfPreventCg
      return n[1]
  of nkReturnStmt:
    if n.len > 0:
      result = easyResultAsgn(n[0])
      if result != nil: incl n.flags, nfPreventCg
  else: discard

type
  InitResultEnum = enum Unknown, InitSkippable, InitRequired

proc allPathsAsgnResult(n: PNode): InitResultEnum =
  # Exceptions coming from calls don't have not be considered here:
  #
  # proc bar(): string = raise newException(...)
  #
  # proc foo(): string =
  #   # optimized out: 'reset(result)'
  #   result = bar()
  #
  # try:
  #   a = foo()
  # except:
  #   echo "a was not written to"
  #
  template allPathsInBranch(it) =
    let a = allPathsAsgnResult(it)
    case a
    of InitRequired: return InitRequired
    of InitSkippable: discard
    of Unknown:
      # sticky, but can be overwritten by InitRequired:
      result = Unknown

  result = Unknown
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for it in n:
      result = allPathsAsgnResult(it)
      if result != Unknown: return result
  of nkAsgn, nkFastAsgn:
    if n[0].kind == nkSym and n[0].sym.kind == skResult:
      if not containsResult(n[1]): result = InitSkippable
      else: result = InitRequired
    elif containsResult(n):
      result = InitRequired
  of nkReturnStmt:
    if n.len > 0:
      if n[0].kind == nkEmpty and result != InitSkippable:
        # This is a bare `return` statement, if `result` was not initialized
        # anywhere else (or if we're not sure about this) let's require it to be
        # initialized. This avoids cases like #9286 where this heuristic lead to
        # wrong code being generated.
        result = InitRequired
      else: result = allPathsAsgnResult(n[0])
  of nkIfStmt, nkIfExpr:
    var exhaustive = false
    result = InitSkippable
    for it in n:
      # Every condition must not use 'result':
      if it.len == 2 and containsResult(it[0]):
        return InitRequired
      if it.len == 1: exhaustive = true
      allPathsInBranch(it.lastSon)
    # if the 'if' statement is not exhaustive and yet it touched 'result'
    # in some way, say Unknown.
    if not exhaustive: result = Unknown
  of nkCaseStmt:
    if containsResult(n[0]): return InitRequired
    result = InitSkippable
    var exhaustive = skipTypes(n[0].typ,
        abstractVarRange-{tyTypeDesc}).kind notin {tyFloat..tyFloat128, tyString}
    for i in 1..<n.len:
      let it = n[i]
      allPathsInBranch(it.lastSon)
      if it.kind == nkElse: exhaustive = true
    if not exhaustive: result = Unknown
  of nkWhileStmt:
    # some dubious code can assign the result in the 'while'
    # condition and that would be fine. Everything else isn't:
    result = allPathsAsgnResult(n[0])
    if result == Unknown:
      result = allPathsAsgnResult(n[1])
      # we cannot assume that the 'while' loop is really executed at least once:
      if result == InitSkippable: result = Unknown
  of harmless:
    result = Unknown
  of nkGotoState, nkBreakState:
    # give up for now.
    result = InitRequired
  of nkSym:
    # some path reads from 'result' before it was written to!
    if n.sym.kind == skResult: result = InitRequired
  of nkTryStmt, nkHiddenTryStmt:
    # We need to watch out for the following problem:
    # try:
    #   result = stuffThatRaises()
    # except:
    #   discard "result was not set"
    #
    # So ... even if the assignment to 'result' is the very first
    # assignment this is not good enough! The only pattern we allow for
    # is 'finally: result = x'
    result = InitSkippable
    for it in n:
      if it.kind == nkFinally:
        result = allPathsAsgnResult(it.lastSon)
      else:
        allPathsInBranch(it.lastSon)
  else:
    for i in 0..<safeLen(n):
      allPathsInBranch(n[i])

proc getProcTypeCast(m: BModule, prc: PSym): Rope =
  result = getTypeDesc(m, prc.loc.t)
  if prc.typ.callConv == ccClosure:
    var rettype, params: Rope
    var check = initIntSet()
    genProcParams(m, prc.typ, rettype, params, check)
    result = "$1(*)$2" % [rettype, params]

proc genProcAux(m: BModule, prc: PSym) =
  var p = newProc(prc, m)
  var header = genProcHeader(m, prc)
  var returnStmt: Rope = nil
  assert(prc.ast != nil)
  let procBody = transformBody(m.g.graph, prc, cache = false)

  if sfPure notin prc.flags and prc.typ.sons[0] != nil:
    if resultPos >= prc.ast.len:
      internalError(m.config, prc.info, "proc has no result symbol")
    let resNode = prc.ast.sons[resultPos]
    let res = resNode.sym # get result symbol
    if not isInvalidReturnType(m.config, prc.typ.sons[0]):
      if sfNoInit in prc.flags: incl(res.flags, sfNoInit)
      if sfNoInit in prc.flags and p.module.compileToCpp and (let val = easyResultAsgn(procBody); val != nil):
        var decl = localVarDecl(p, resNode)
        var a: TLoc
        initLocExprSingleUse(p, val, a)
        linefmt(p, cpsStmts, "$1 = $2;$n", decl, rdLoc(a))
      else:
        # declare the result symbol:
        assignLocalVar(p, resNode)
        assert(res.loc.r != nil)
        initLocalVar(p, res, immediateAsgn=false)
      returnStmt = ropecg(p.module, "\treturn $1;$n", rdLoc(res.loc))
    else:
      fillResult(p.config, resNode)
      assignParam(p, res, prc.typ[0])
      # We simplify 'unsureAsgn(result, nil); unsureAsgn(result, x)'
      # to 'unsureAsgn(result, x)'
      # Sketch why this is correct: If 'result' points to a stack location
      # the 'unsureAsgn' is a nop. If it points to a global variable the
      # global is either 'nil' or points to valid memory and so the RC operation
      # succeeds without touching not-initialized memory.
      if sfNoInit in prc.flags: discard
      elif allPathsAsgnResult(procBody) == InitSkippable: discard
      else:
        resetLoc(p, res.loc)
      if skipTypes(res.typ, abstractInst).kind == tyArray:
        #incl(res.loc.flags, lfIndirect)
        res.loc.storage = OnUnknown

  for i in countup(1, sonsLen(prc.typ.n) - 1):
    let param = prc.typ.n.sons[i].sym
    if param.typ.isCompileTimeOnly: continue
    assignParam(p, param, prc.typ[0])
  closureSetup(p, prc)
  genStmts(p, procBody) # modifies p.locals, p.init, etc.
  var generatedProc: Rope
  if sfNoReturn in prc.flags:
    if hasDeclspec in extccomp.CC[p.config.cCompiler].props:
      header = "__declspec(noreturn) " & header
  if sfPure in prc.flags:
    if hasDeclspec in extccomp.CC[p.config.cCompiler].props:
      header = "__declspec(naked) " & header
    generatedProc = ropecg(p.module, "$N$1 {$n$2$3$4}$N$N",
                         header, p.s(cpsLocals), p.s(cpsInit), p.s(cpsStmts))
  else:
    generatedProc = ropecg(p.module, "$N$1 {$N", header)
    add(generatedProc, initGCFrame(p))
    if optStackTrace in prc.options:
      add(generatedProc, p.s(cpsLocals))
      var procname = makeCString(prc.name.s)
      add(generatedProc, initFrame(p, procname, quotedFilename(p.config, prc.info)))
    else:
      add(generatedProc, p.s(cpsLocals))
    if optProfiler in prc.options:
      # invoke at proc entry for recursion:
      appcg(p, cpsInit, "\t#nimProfile();$n", [])
    if p.beforeRetNeeded: add(generatedProc, "{")
    add(generatedProc, p.s(cpsInit))
    add(generatedProc, p.s(cpsStmts))
    if p.beforeRetNeeded: add(generatedProc, ~"\t}BeforeRet_: ;$n")
    add(generatedProc, deinitGCFrame(p))
    if optStackTrace in prc.options: add(generatedProc, deinitFrame(p))
    add(generatedProc, returnStmt)
    add(generatedProc, ~"}$N")
  add(m.s[cfsProcs], generatedProc)
  if isReloadable(m, prc):
    addf(m.s[cfsDynLibInit], "\t$1 = ($3) hcrRegisterProc($4, \"$1\", (void*)$2);$n",
         [prc.loc.r, prc.loc.r & "_actual", getProcTypeCast(m, prc), getModuleDllPath(m, prc)])

proc requiresExternC(m: BModule; sym: PSym): bool {.inline.} =
  result = (sfCompileToCpp in m.module.flags and
           sfCompileToCpp notin sym.getModule().flags and
           m.config.cmd != cmdCompileToCpp) or (
           sym.flags * {sfImportc, sfInfixCall, sfCompilerProc} == {sfImportc} and
           sym.magic == mNone and
           m.config.cmd == cmdCompileToCpp)

proc genProcPrototype(m: BModule, sym: PSym) =
  useHeader(m, sym)
  if lfNoDecl in sym.loc.flags: return
  if lfDynamicLib in sym.loc.flags:
    if getModule(sym).id != m.module.id and
        not containsOrIncl(m.declaredThings, sym.id):
      add(m.s[cfsVars], ropecg(m, "$1 $2 $3;$n",
                        rope(if isReloadable(m, sym): "static" else: "extern"),
                        getTypeDesc(m, sym.loc.t), mangleDynLibProc(sym)))
      if isReloadable(m, sym):
        addf(m.s[cfsDynLibInit], "\t$1 = ($2) hcrGetProc($3, \"$1\");$n",
             [mangleDynLibProc(sym), getTypeDesc(m, sym.loc.t), getModuleDllPath(m, sym)])
  elif not containsOrIncl(m.declaredProtos, sym.id):
    let asPtr = isReloadable(m, sym)
    var header = genProcHeader(m, sym, asPtr)
    if not asPtr:
      if sfNoReturn in sym.flags and hasDeclspec in extccomp.CC[m.config.cCompiler].props:
        header = "__declspec(noreturn) " & header
      if sym.typ.callConv != ccInline and requiresExternC(m, sym):
        header = "extern \"C\" " & header
      if sfPure in sym.flags and hasAttribute in CC[m.config.cCompiler].props:
        header.add(" __attribute__((naked))")
      if sfNoReturn in sym.flags and hasAttribute in CC[m.config.cCompiler].props:
        header.add(" __attribute__((noreturn))")
    add(m.s[cfsProcHeaders], ropecg(m, "$1;$N", header))

# TODO: figure out how to rename this - it DOES generate a forward declaration
proc genProcNoForward(m: BModule, prc: PSym) =
  if lfImportCompilerProc in prc.loc.flags:
    fillProcLoc(m, prc.ast[namePos])
    useHeader(m, prc)
    # dependency to a compilerproc:
    discard cgsym(m, prc.name.s)
    return
  if lfNoDecl in prc.loc.flags:
    fillProcLoc(m, prc.ast[namePos])
    genProcPrototype(m, prc)
  elif prc.typ.callConv == ccInline:
    # We add inline procs to the calling module to enable C based inlining.
    # This also means that a check with ``q.declaredThings`` is wrong, we need
    # a check for ``m.declaredThings``.
    if not containsOrIncl(m.declaredThings, prc.id):
      #if prc.loc.k == locNone:
      # mangle the inline proc based on the module where it is defined - not on the first module that uses it
      fillProcLoc(findPendingModule(m, prc), prc.ast[namePos])
      #elif {sfExportc, sfImportc} * prc.flags == {}:
      #  # reset name to restore consistency in case of hashing collisions:
      #  echo "resetting ", prc.id, " by ", m.module.name.s
      #  prc.loc.r = nil
      #  prc.loc.r = mangleName(m, prc)
      genProcPrototype(m, prc)
      genProcAux(m, prc)
  elif lfDynamicLib in prc.loc.flags:
    var q = findPendingModule(m, prc)
    fillProcLoc(q, prc.ast[namePos])
    genProcPrototype(m, prc)
    if q != nil and not containsOrIncl(q.declaredThings, prc.id):
      symInDynamicLib(q, prc)
      # register the procedure even though it is in a different dynamic library and will not be
      # reloadable (and has no _actual suffix) - other modules will need to be able to get it through
      # the hcr dynlib (also put it in the DynLibInit section - right after it gets loaded)
      if isReloadable(q, prc):
        addf(q.s[cfsDynLibInit], "\t$1 = ($2) hcrRegisterProc($3, \"$1\", (void*)$1);$n",
            [prc.loc.r, getTypeDesc(q, prc.loc.t), getModuleDllPath(m, q.module)])
    else:
      symInDynamicLibPartial(m, prc)
  elif sfImportc notin prc.flags:
    var q = findPendingModule(m, prc)
    fillProcLoc(q, prc.ast[namePos])
    # generate a getProc call to initialize the pointer for this
    # externally-to-the-current-module defined proc, also important
    # to do the declaredProtos check before the call to genProcPrototype
    if isReloadable(m, prc) and prc.id notin m.declaredProtos and
      q != nil and q.module.id != m.module.id:
      addf(m.s[cfsDynLibInit], "\t$1 = ($2) hcrGetProc($3, \"$1\");$n",
           [prc.loc.r, getProcTypeCast(m, prc), getModuleDllPath(m, prc)])
    genProcPrototype(m, prc)
    if q != nil and not containsOrIncl(q.declaredThings, prc.id):
      # make sure there is a "prototype" in the external module
      # which will actually become a function pointer
      if isReloadable(m, prc):
        genProcPrototype(q, prc)
      genProcAux(q, prc)
  else:
    fillProcLoc(m, prc.ast[namePos])
    useHeader(m, prc)
    if sfInfixCall notin prc.flags: genProcPrototype(m, prc)

proc requestConstImpl(p: BProc, sym: PSym) =
  var m = p.module
  useHeader(m, sym)
  if sym.loc.k == locNone:
    fillLoc(sym.loc, locData, sym.ast, mangleName(p.module, sym), OnStatic)
  if lfNoDecl in sym.loc.flags: return
  # declare implementation:
  var q = findPendingModule(m, sym)
  if q != nil and not containsOrIncl(q.declaredThings, sym.id):
    assert q.initProc.module == q
    addf(q.s[cfsData], "NIM_CONST $1 $2 = $3;$n",
        [getTypeDesc(q, sym.typ), sym.loc.r, genConstExpr(q.initProc, sym.ast)])
  # declare header:
  if q != m and not containsOrIncl(m.declaredThings, sym.id):
    assert(sym.loc.r != nil)
    let headerDecl = "extern NIM_CONST $1 $2;$n" %
        [getTypeDesc(m, sym.loc.t), sym.loc.r]
    add(m.s[cfsData], headerDecl)
    if sfExportc in sym.flags and p.module.g.generatedHeader != nil:
      add(p.module.g.generatedHeader.s[cfsData], headerDecl)

proc isActivated(prc: PSym): bool = prc.typ != nil

proc genProc(m: BModule, prc: PSym) =
  if sfBorrow in prc.flags or not isActivated(prc): return
  if sfForward in prc.flags:
    addForwardedProc(m, prc)
    fillProcLoc(m, prc.ast[namePos])
  else:
    genProcNoForward(m, prc)
    if {sfExportc, sfCompilerProc} * prc.flags == {sfExportc} and
        m.g.generatedHeader != nil and lfNoDecl notin prc.loc.flags:
      genProcPrototype(m.g.generatedHeader, prc)
      if prc.typ.callConv == ccInline:
        if not containsOrIncl(m.g.generatedHeader.declaredThings, prc.id):
          genProcAux(m.g.generatedHeader, prc)

proc genVarPrototype(m: BModule, n: PNode) =
  #assert(sfGlobal in sym.flags)
  let sym = n.sym
  useHeader(m, sym)
  fillLoc(sym.loc, locGlobalVar, n, mangleName(m, sym), OnHeap)
  if treatGlobalDifferentlyForHCR(m, sym): incl(sym.loc.flags, lfIndirect)

  if (lfNoDecl in sym.loc.flags) or contains(m.declaredThings, sym.id):
    return
  if sym.owner.id != m.module.id:
    # else we already have the symbol generated!
    assert(sym.loc.r != nil)
    if sfThread in sym.flags:
      declareThreadVar(m, sym, true)
    else:
      incl(m.declaredThings, sym.id)
      add(m.s[cfsVars], if m.hcrOn: "static " else: "extern ")
      add(m.s[cfsVars], getTypeDesc(m, sym.loc.t))
      if m.hcrOn: add(m.s[cfsVars], "*")
      if lfDynamicLib in sym.loc.flags: add(m.s[cfsVars], "*")
      if sfRegister in sym.flags: add(m.s[cfsVars], " register")
      if sfVolatile in sym.flags: add(m.s[cfsVars], " volatile")
      addf(m.s[cfsVars], " $1;$n", [sym.loc.r])
      if m.hcrOn: addf(m.initProc.procSec(cpsLocals),
        "\t$1 = ($2*)hcrGetGlobal($3, \"$1\");$n", [sym.loc.r,
        getTypeDesc(m, sym.loc.t), getModuleDllPath(m, sym)])

proc addIntTypes(result: var Rope; conf: ConfigRef) {.inline.} =
  addf(result, "#define NIM_INTBITS $1\L", [
    platform.CPU[conf.target.targetCPU].intSize.rope])
  if conf.cppCustomNamespace.len > 0:
    result.add("#define USE_NIM_NAMESPACE ")
    result.add(conf.cppCustomNamespace)
    result.add("\L")

proc getCopyright(conf: ConfigRef; cfile: Cfile): Rope =
  if optCompileOnly in conf.globalOptions:
    result = ("/* Generated by Nim Compiler v$1 */$N" &
        "/*   (c) " & copyrightYear & " Andreas Rumpf */$N" &
        "/* The generated code is subject to the original license. */$N") %
        [rope(VersionAsString)]
  else:
    result = ("/* Generated by Nim Compiler v$1 */$N" &
        "/*   (c) " & copyrightYear & " Andreas Rumpf */$N" &
        "/* The generated code is subject to the original license. */$N" &
        "/* Compiled for: $2, $3, $4 */$N" &
        "/* Command for C compiler:$n   $5 */$N") %
        [rope(VersionAsString),
        rope(platform.OS[conf.target.targetOS].name),
        rope(platform.CPU[conf.target.targetCPU].name),
        rope(extccomp.CC[conf.cCompiler].name),
        rope(getCompileCFileCmd(conf, cfile))]

proc getFileHeader(conf: ConfigRef; cfile: Cfile): Rope =
  result = getCopyright(conf, cfile)
  if conf.hcrOn: add(result, "#define NIM_HOT_CODE_RELOADING\L")
  addIntTypes(result, conf)

proc getSomeNameForModule(m: PSym): Rope =
  assert m.kind == skModule
  assert m.owner.kind == skPackage
  if {sfSystemModule, sfMainModule} * m.flags == {}:
    result = m.owner.name.s.mangle.rope
    result.add "_"
  result.add m.name.s.mangle

proc getSomeInitName(m: BModule, suffix: string): Rope =
  if not m.hcrOn:
    result = getSomeNameForModule(m.module)
  result.add suffix

proc getInitName(m: BModule): Rope =
  if sfMainModule in m.module.flags:
    # generate constant name for main module, for "easy" debugging.
    result = rope"NimMainModule"
  else:
    result = getSomeInitName(m, "Init000")

proc getDatInitName(m: BModule): Rope = getSomeInitName(m, "DatInit000")
proc getHcrInitName(m: BModule): Rope = getSomeInitName(m, "HcrInit000")

proc hcrGetProcLoadCode(m: BModule, sym, prefix, handle, getProcFunc: string): Rope

proc genMainProc(m: BModule) =
  ## this function is called in cgenWriteModules after all modules are closed,
  ## it means raising dependency on the symbols is too late as it will not propogate
  ## into other modules, only simple rope manipulations are allowed

  var preMainCode: Rope
  if m.hcrOn:
    proc loadLib(handle: string, name: string): Rope =
      let prc = magicsys.getCompilerProc(m.g.graph, name)
      assert prc != nil
      let n = newStrNode(nkStrLit, prc.annex.path.strVal)
      n.info = prc.annex.path.info
      appcg(m, result, "\tif (!($1 = #nimLoadLibrary($2)))$N" &
                       "\t\t#nimLoadLibraryError($2);$N",
                       [handle.rope, genStringLiteral(m, n)])

    add(preMainCode, loadLib("hcr_handle", "hcrGetProc"))
    add(preMainCode, "\tvoid* rtl_handle;$N")
    add(preMainCode, loadLib("rtl_handle", "nimGC_setStackBottom"))
    add(preMainCode, hcrGetProcLoadCode(m, "nimGC_setStackBottom", "nimrtl_", "rtl_handle", "nimGetProcAddr"))
    add(preMainCode, "\tinner = PreMain;$N")
    add(preMainCode, "\tinitStackBottomWith_actual((void *)&inner);$N")
    add(preMainCode, "\t(*inner)();$N")
  else:
    add(preMainCode, "\tPreMain();$N")

  let
    # not a big deal if we always compile these 3 global vars... makes the HCR code easier
    PosixCmdLine =
      "int cmdCount;$N" &
      "char** cmdLine;$N" &
      "char** gEnv;$N"

    # The use of a volatile function pointer to call Pre/NimMainInner
    # prevents inlining of the NimMainInner function and dependent
    # functions, which might otherwise merge their stack frames.
    PreMainBody = "$N" &
      "void PreMainInner(void) {$N" &
      "$2" &
      "$3" &
      "}$N$N" &
      PosixCmdLine &
      "void PreMain(void) {$N" &
      "\tvoid (*volatile inner)(void);$N" &
      "\tinner = PreMainInner;$N" &
      "$1" &
      "\t(*inner)();$N" &
      "}$N$N"

    MainProcs =
      "\tNimMain();$N"

    MainProcsWithResult =
      MainProcs & ("\treturn " & (if m.hcrOn: "*" else: "") & "nim_program_result;$N")

    NimMainInner = "N_CDECL(void, NimMainInner)(void) {$N" &
        "$1" &
      "}$N$N"

    NimMainProc =
      "N_CDECL(void, NimMain)(void) {$N" &
        "\tvoid (*volatile inner)(void);$N" &
        $preMainCode &
        "\tinner = NimMainInner;$N" &
        "$2" &
        "\t(*inner)();$N" &
      "}$N$N"

    NimMainBody = NimMainInner & NimMainProc

    PosixCMain =
      "int main(int argc, char** args, char** env) {$N" &
        "\tcmdLine = args;$N" &
        "\tcmdCount = argc;$N" &
        "\tgEnv = env;$N" &
        MainProcsWithResult &
      "}$N$N"

    StandaloneCMain =
      "int main(void) {$N" &
        MainProcs &
        "\treturn 0;$N" &
      "}$N$N"

    WinNimMain = NimMainBody

    WinCMain = "N_STDCALL(int, WinMain)(HINSTANCE hCurInstance, $N" &
      "                        HINSTANCE hPrevInstance, $N" &
      "                        LPSTR lpCmdLine, int nCmdShow) {$N" &
      MainProcsWithResult & "}$N$N"

    WinNimDllMain = NimMainInner & "N_LIB_EXPORT " & NimMainProc

    WinCDllMain =
      "BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdreason, $N" &
      "                    LPVOID lpvReserved) {$N" &
      "\tif(fwdreason == DLL_PROCESS_ATTACH) {$N" & MainProcs & "}$N" &
      "\treturn 1;$N}$N$N"

    PosixNimDllMain = WinNimDllMain

    PosixCDllMain =
      "void NIM_POSIX_INIT NimMainInit(void) {$N" &
        MainProcs &
      "}$N$N"

    GenodeNimMain =
      "extern Genode::Env *nim_runtime_env;$N" &
      "extern void nim_component_construct(Genode::Env*);$N$N" &
      NimMainBody

    ComponentConstruct =
      "void Libc::Component::construct(Libc::Env &env) {$N" &
      "\t// Set Env used during runtime initialization$N" &
      "\tnim_runtime_env = &env;$N" &
      "\tLibc::with_libc([&] () {$N\t" &
      "\t// Initialize runtime and globals$N" &
      MainProcs &
      "\t// Call application construct$N" &
      "\t\tnim_component_construct(&env);$N" &
      "\t});$N" &
      "}$N$N"

  var nimMain, otherMain: FormatStr
  if m.config.target.targetOS == osWindows and
      m.config.globalOptions * {optGenGuiApp, optGenDynLib} != {}:
    if optGenGuiApp in m.config.globalOptions:
      nimMain = WinNimMain
      otherMain = WinCMain
    else:
      nimMain = WinNimDllMain
      otherMain = WinCDllMain
    m.includeHeader("<windows.h>")
  elif m.config.target.targetOS == osGenode:
    nimMain = GenodeNimMain
    otherMain = ComponentConstruct
    m.includeHeader("<libc/component.h>")
  elif optGenDynLib in m.config.globalOptions:
    nimMain = PosixNimDllMain
    otherMain = PosixCDllMain
  elif m.config.target.targetOS == osStandalone:
    nimMain = NimMainBody
    otherMain = StandaloneCMain
  else:
    nimMain = NimMainBody
    otherMain = PosixCMain
  if optEndb in m.config.options:
    for i in 0..<m.config.m.fileInfos.len:
      m.g.breakpoints.addf("dbgRegisterFilename($1);$N",
        [m.config.m.fileInfos[i].projPath.string.makeCString])

  let initStackBottomCall =
    if m.config.target.targetOS == osStandalone or m.config.selectedGC == gcNone: "".rope
    else: ropecg(m, "\t#initStackBottomWith((void *)&inner);$N")
  inc(m.labels)
  appcg(m, m.s[cfsProcs], PreMainBody, [
    m.g.mainDatInit, m.g.breakpoints, m.g.otherModsInit])

  appcg(m, m.s[cfsProcs], nimMain,
        [m.g.mainModInit, initStackBottomCall, rope(m.labels)])
  if optNoMain notin m.config.globalOptions:
    if m.config.cppCustomNamespace.len > 0:
      m.s[cfsProcs].add closeNamespaceNim() & "using namespace " & m.config.cppCustomNamespace & ";\L"

    appcg(m, m.s[cfsProcs], otherMain, [])
    if m.config.cppCustomNamespace.len > 0:
      m.s[cfsProcs].add openNamespaceNim(m.config.cppCustomNamespace)

proc registerModuleToMain(g: BModuleList; m: BModule) =
  let
    init = m.getInitName
    datInit = m.getDatInitName

  if m.hcrOn:
    var hcr_module_meta = "$nN_LIB_PRIVATE const char* hcr_module_list[] = {$n" % []
    let systemModulePath = getModuleDllPath(m, g.modules[g.graph.config.m.systemFileIdx.int].module)
    let mainModulePath = getModuleDllPath(m, m.module)
    if sfMainModule in m.module.flags:
      addf(hcr_module_meta, "\t$1,$n", [systemModulePath])
    g.graph.importDeps.withValue(FileIndex(m.module.position), deps):
      for curr in deps[]:
        addf(hcr_module_meta, "\t$1,$n", [getModuleDllPath(m, g.modules[curr.int].module)])
    addf(hcr_module_meta, "\t\"\"};$n", [])
    addf(hcr_module_meta, "$nN_LIB_EXPORT N_NIMCALL(void**, HcrGetImportedModules)() { return (void**)hcr_module_list; }$n", [])
    addf(hcr_module_meta, "$nN_LIB_EXPORT N_NIMCALL(char*, HcrGetSigHash)() { return \"$1\"; }$n$n",
                          [($sigHash(m.module)).rope])
    if sfMainModule in m.module.flags:
      add(g.mainModProcs, hcr_module_meta)
      addf(g.mainModProcs, "static void* hcr_handle;$N", [])
      addf(g.mainModProcs, "N_LIB_EXPORT N_NIMCALL(void, $1)(void);$N", [init])
      addf(g.mainModProcs, "N_LIB_EXPORT N_NIMCALL(void, $1)(void);$N", [datInit])
      addf(g.mainModProcs, "N_LIB_EXPORT N_NIMCALL(void, $1)(void*, N_NIMCALL_PTR(void*, getProcAddr)(void*, char*));$N", [m.getHcrInitName])
      addf(g.mainModProcs, "N_LIB_EXPORT N_NIMCALL(void, HcrCreateTypeInfos)(void);$N", [])
      addf(g.mainModInit, "\t$1();$N", [init])
      addf(g.otherModsInit, "\thcrInit((void**)hcr_module_list, $1, $2, $3, hcr_handle, nimGetProcAddr);$n",
                            [mainModulePath, systemModulePath, datInit])
      addf(g.mainDatInit, "\t$1(hcr_handle, nimGetProcAddr);$N", [m.getHcrInitName])
      addf(g.mainDatInit, "\thcrAddModule($1);\n", [mainModulePath])
      addf(g.mainDatInit, "\tHcrCreateTypeInfos();$N", [])
      # nasty nasty hack to get the command line functionality working with HCR
      # register the 2 variables on behalf of the os module which might not even
      # be loaded (in which case it will get collected but that is not a problem)
      let osModulePath = ($systemModulePath).replace("stdlib_system", "stdlib_os").rope
      addf(g.mainDatInit, "\thcrAddModule($1);\n", [osModulePath])
      add(g.mainDatInit, "\tint* cmd_count;\n")
      add(g.mainDatInit, "\tchar*** cmd_line;\n")
      addf(g.mainDatInit, "\thcrRegisterGlobal($1, \"cmdCount\", sizeof(cmd_count), NULL, (void**)&cmd_count);$N", [osModulePath])
      addf(g.mainDatInit, "\thcrRegisterGlobal($1, \"cmdLine\", sizeof(cmd_line), NULL, (void**)&cmd_line);$N", [osModulePath])
      add(g.mainDatInit, "\t*cmd_count = cmdCount;\n")
      add(g.mainDatInit, "\t*cmd_line = cmdLine;\n")
    else:
      add(m.s[cfsInitProc], hcr_module_meta)
    return

  if m.s[cfsDatInitProc].len > 0:
    addf(g.mainModProcs, "N_LIB_PRIVATE N_NIMCALL(void, $1)(void);$N", [datInit])
    addf(g.mainDatInit, "\t$1();$N", [datInit])

  # Initialization of TLS and GC should be done in between
  # systemDatInit and systemInit calls if any
  if sfSystemModule in m.module.flags:
    if emulatedThreadVars(m.config) and m.config.target.targetOS != osStandalone:
      add(g.mainDatInit, ropecg(m, "\t#initThreadVarsEmulation();$N"))
    if m.config.target.targetOS != osStandalone and m.config.selectedGC != gcNone:
      add(g.mainDatInit, ropecg(m, "\t#initStackBottomWith((void *)&inner);$N"))

  if m.s[cfsInitProc].len > 0:
    addf(g.mainModProcs, "N_LIB_PRIVATE N_NIMCALL(void, $1)(void);$N", [init])
    let initCall = "\t$1();$N" % [init]
    if sfMainModule in m.module.flags:
      add(g.mainModInit, initCall)
    elif sfSystemModule in m.module.flags:
      add(g.mainDatInit, initCall) # systemInit must called right after systemDatInit if any
    else:
      add(g.otherModsInit, initCall)

proc genDatInitCode(m: BModule) =
  ## this function is called in cgenWriteModules after all modules are closed,
  ## it means raising dependency on the symbols is too late as it will not propogate
  ## into other modules, only simple rope manipulations are allowed

  var moduleDatInitRequired = m.hcrOn

  var prc = "$1 N_NIMCALL(void, $2)(void) {$N" %
    [rope(if m.hcrOn: "N_LIB_EXPORT" else: "N_LIB_PRIVATE"), getDatInitName(m)]

  # we don't want to break into such init code - could happen if a line
  # directive from a function written by the user spills after itself
  genCLineDir(prc, "generated_not_to_break_here", 999999, m.config)

  for i in cfsTypeInit1..cfsDynLibInit:
    if m.s[i].len != 0:
      moduleDatInitRequired = true
      add(prc, genSectionStart(i, m.config))
      add(prc, m.s[i])
      add(prc, genSectionEnd(i, m.config))

  addf(prc, "}$N$N", [])

  if moduleDatInitRequired:
    add(m.s[cfsDatInitProc], prc)

# Very similar to the contents of symInDynamicLib - basically only the
# things needed for the hot code reloading runtime procs to be loaded
proc hcrGetProcLoadCode(m: BModule, sym, prefix, handle, getProcFunc: string): Rope =
  let prc = magicsys.getCompilerProc(m.g.graph, sym)
  assert prc != nil
  fillProcLoc(m, prc.ast[namePos])

  var extname = prefix & sym
  var tmp = mangleDynLibProc(prc)
  prc.loc.r = tmp
  prc.typ.sym = nil

  if not containsOrIncl(m.declaredThings, prc.id):
    addf(m.s[cfsVars], "static $2 $1;$n", [prc.loc.r, getTypeDesc(m, prc.loc.t)])

  result = "\t$1 = ($2) $3($4, $5);$n" %
      [tmp, getTypeDesc(m, prc.typ), getProcFunc.rope, handle.rope, makeCString(prefix & sym)]

proc genInitCode(m: BModule) =
  ## this function is called in cgenWriteModules after all modules are closed,
  ## it means raising dependency on the symbols is too late as it will not propogate
  ## into other modules, only simple rope manipulations are allowed
  var moduleInitRequired = m.hcrOn
  let initname = getInitName(m)
  var prc = "$1 N_NIMCALL(void, $2)(void) {$N" %
    [rope(if m.hcrOn: "N_LIB_EXPORT" else: "N_LIB_PRIVATE"), initname]
  # we don't want to break into such init code - could happen if a line
  # directive from a function written by the user spills after itself
  genCLineDir(prc, "generated_not_to_break_here", 999999, m.config)
  if m.typeNodes > 0:
    if m.hcrOn:
      appcg(m, m.s[cfsTypeInit1], "\t#TNimNode* $1;$N", [m.typeNodesName])
      appcg(m, m.s[cfsTypeInit1], "\thcrRegisterGlobal($3, \"$1_$2\", sizeof(TNimNode) * $2, NULL, (void**)&$1);$N",
            [m.typeNodesName, rope(m.typeNodes), getModuleDllPath(m, m.module)])
    else:
      appcg(m, m.s[cfsTypeInit1], "static #TNimNode $1[$2];$n",
            [m.typeNodesName, rope(m.typeNodes)])
  if m.nimTypes > 0:
    appcg(m, m.s[cfsTypeInit1], "static #TNimType $1[$2];$n",
          [m.nimTypesName, rope(m.nimTypes)])

  if m.hcrOn:
    addf(prc, "\tint* nim_hcr_dummy_ = 0;$n" &
              "\tNIM_BOOL nim_hcr_do_init_ = " &
                  "hcrRegisterGlobal($1, \"module_initialized_\", 1, NULL, (void**)&nim_hcr_dummy_);$n",
      [getModuleDllPath(m, m.module)])

  template writeSection(thing: untyped, section: TCProcSection, addHcrGuards = false) =
    if m.thing.s(section).len > 0:
      moduleInitRequired = true
      if addHcrGuards: add(prc, "\tif (nim_hcr_do_init_) {\n\n")
      add(prc, genSectionStart(section, m.config))
      add(prc, m.thing.s(section))
      add(prc, genSectionEnd(section, m.config))
      if addHcrGuards: add(prc, "\n\t} // nim_hcr_do_init_\n")

  if m.preInitProc.s(cpsInit).len > 0 or m.preInitProc.s(cpsStmts).len > 0:
    # Give this small function its own scope
    addf(prc, "{$N", [])
    # Keep a bogus frame in case the code needs one
    add(prc, ~"\tTFrame FR_; FR_.len = 0;$N")

    writeSection(preInitProc, cpsLocals)
    writeSection(preInitProc, cpsInit, m.hcrOn)
    writeSection(preInitProc, cpsStmts)
    addf(prc, "}$N", [])

  # add new scope for following code, because old vcc compiler need variable
  # be defined at the top of the block
  addf(prc, "{$N", [])
  if m.initProc.gcFrameId > 0:
    moduleInitRequired = true
    add(prc, initGCFrame(m.initProc))

  writeSection(initProc, cpsLocals)

  if m.initProc.s(cpsInit).len > 0 or m.initProc.s(cpsStmts).len > 0:
    moduleInitRequired = true
    if optStackTrace in m.initProc.options and frameDeclared notin m.flags:
      # BUT: the generated init code might depend on a current frame, so
      # declare it nevertheless:
      incl m.flags, frameDeclared
      if preventStackTrace notin m.flags:
        var procname = makeCString(m.module.name.s)
        add(prc, initFrame(m.initProc, procname, quotedFilename(m.config, m.module.info)))
      else:
        add(prc, ~"\tTFrame FR_; FR_.len = 0;$N")

    writeSection(initProc, cpsInit, m.hcrOn)
    writeSection(initProc, cpsStmts)

    if optStackTrace in m.initProc.options and preventStackTrace notin m.flags:
      add(prc, deinitFrame(m.initProc))

  if m.initProc.gcFrameId > 0:
    moduleInitRequired = true
    add(prc, deinitGCFrame(m.initProc))
  addf(prc, "}$N", [])

  addf(prc, "}$N$N", [])

  # we cannot simply add the init proc to ``m.s[cfsProcs]`` anymore because
  # that would lead to a *nesting* of merge sections which the merger does
  # not support. So we add it to another special section: ``cfsInitProc``

  if m.hcrOn:
    var procsToLoad = @["hcrRegisterProc", "hcrGetProc", "hcrRegisterGlobal", "hcrGetGlobal"]

    addf(m.s[cfsInitProc], "N_LIB_EXPORT N_NIMCALL(void, $1)(void* handle, N_NIMCALL_PTR(void*, getProcAddr)(void*, char*)) {$N", [getHcrInitName(m)])
    if sfMainModule in m.module.flags:
      # additional procs to load
      procsToLoad.add("hcrInit")
      procsToLoad.add("hcrAddModule")
    # load procs
    for curr in procsToLoad:
      add(m.s[cfsInitProc], hcrGetProcLoadCode(m, curr, "", "handle", "getProcAddr"))
    addf(m.s[cfsInitProc], "}$N$N", [])

  for i, el in pairs(m.extensionLoaders):
    if el != nil:
      let ex = "NIM_EXTERNC N_NIMCALL(void, nimLoadProcs$1)(void) {$2}$N$N" %
        [(i.ord - '0'.ord).rope, el]
      moduleInitRequired = true
      add(prc, ex)

  if moduleInitRequired or sfMainModule in m.module.flags:
    add(m.s[cfsInitProc], prc)

  genDatInitCode(m)

  if m.hcrOn:
    addf(m.s[cfsInitProc], "N_LIB_EXPORT N_NIMCALL(void, HcrCreateTypeInfos)(void) {$N", [])
    add(m.s[cfsInitProc], m.hcrCreateTypeInfosProc)
    addf(m.s[cfsInitProc], "}$N$N", [])

  registerModuleToMain(m.g, m)

proc genModule(m: BModule, cfile: Cfile): Rope =
  var moduleIsEmpty = true

  result = getFileHeader(m.config, cfile)
  result.add(genMergeInfo(m))

  if m.config.cppCustomNamespace.len > 0:
    result.add openNamespaceNim(m.config.cppCustomNamespace)

  generateThreadLocalStorage(m)
  generateHeaders(m)
  add(result, genSectionStart(cfsHeaders, m.config))
  add(result, m.s[cfsHeaders])
  add(result, genSectionEnd(cfsHeaders, m.config))
  add(result, genSectionStart(cfsFrameDefines, m.config))
  add(result, m.s[cfsFrameDefines])
  add(result, genSectionEnd(cfsFrameDefines, m.config))

  for i in countup(cfsForwardTypes, cfsProcs):
    if m.s[i].len > 0:
      moduleIsEmpty = false
      add(result, genSectionStart(i, m.config))
      add(result, m.s[i])
      add(result, genSectionEnd(i, m.config))

  if m.s[cfsInitProc].len > 0:
    moduleIsEmpty = false
    add(result, m.s[cfsInitProc])
  if m.s[cfsDatInitProc].len > 0 or m.hcrOn:
    moduleIsEmpty = false
    add(result, m.s[cfsDatInitProc])

  if m.config.cppCustomNamespace.len > 0:
    result.add closeNamespaceNim()

  if moduleIsEmpty:
    result = nil

proc newPreInitProc(m: BModule): BProc =
  result = newProc(nil, m)
  # little hack so that unique temporaries are generated:
  result.labels = 100_000

proc initProcOptions(m: BModule): TOptions =
  let opts = m.config.options
  if sfSystemModule in m.module.flags: opts-{optStackTrace} else: opts

proc rawNewModule(g: BModuleList; module: PSym, filename: AbsoluteFile): BModule =
  new(result)
  result.g = g
  result.tmpBase = rope("TM" & $hashOwner(module) & "_")
  result.headerFiles = @[]
  result.declaredThings = initIntSet()
  result.declaredProtos = initIntSet()
  result.cfilename = filename
  result.filename = filename
  result.typeCache = initTable[SigHash, Rope]()
  result.forwTypeCache = initTable[SigHash, Rope]()
  result.module = module
  result.typeInfoMarker = initTable[SigHash, Rope]()
  result.sigConflicts = initCountTable[SigHash]()
  result.initProc = newProc(nil, result)
  result.initProc.options = initProcOptions(result)
  result.preInitProc = newPreInitProc(result)
  initNodeTable(result.dataCache)
  result.typeStack = @[]
  result.typeNodesName = getTempName(result)
  result.nimTypesName = getTempName(result)
  # no line tracing for the init sections of the system module so that we
  # don't generate a TFrame which can confuse the stack botton initialization:
  if sfSystemModule in module.flags:
    incl result.flags, preventStackTrace
    excl(result.preInitProc.options, optStackTrace)
  let ndiName = if optCDebug in g.config.globalOptions: changeFileExt(completeCFilePath(g.config, filename), "ndi")
                else: AbsoluteFile""
  open(result.ndi, ndiName, g.config)

proc nullify[T](arr: var T) =
  for i in low(arr)..high(arr):
    arr[i] = Rope(nil)

proc rawNewModule(g: BModuleList; module: PSym; conf: ConfigRef): BModule =
  result = rawNewModule(g, module, AbsoluteFile toFullPath(conf, module.position.FileIndex))

proc newModule(g: BModuleList; module: PSym; conf: ConfigRef): BModule =
  # we should create only one cgen module for each module sym
  result = rawNewModule(g, module, conf)
  if module.position >= g.modules.len:
    setLen(g.modules, module.position + 1)
  #growCache g.modules, module.position
  g.modules[module.position] = result

template injectG() {.dirty.} =
  if graph.backend == nil:
    graph.backend = newModuleList(graph)
  let g = BModuleList(graph.backend)

proc myOpen(graph: ModuleGraph; module: PSym): PPassContext =
  injectG()
  result = newModule(g, module, graph.config)
  if optGenIndex in graph.config.globalOptions and g.generatedHeader == nil:
    let f = if graph.config.headerFile.len > 0: AbsoluteFile graph.config.headerFile
            else: graph.config.projectFull
    g.generatedHeader = rawNewModule(g, module,
      changeFileExt(completeCFilePath(graph.config, f), hExt))
    incl g.generatedHeader.flags, isHeaderFile

proc writeHeader(m: BModule) =
  var result = ("/* Generated by Nim Compiler v$1 */$N" &
        "/*   (c) 2017 Andreas Rumpf */$N" &
        "/* The generated code is subject to the original license. */$N") %
        [rope(VersionAsString)]

  var guard = "__$1__" % [m.filename.splitFile.name.rope]
  result.addf("#ifndef $1$n#define $1$n", [guard])
  addIntTypes(result, m.config)
  generateHeaders(m)

  generateThreadLocalStorage(m)
  for i in countup(cfsHeaders, cfsProcs):
    add(result, genSectionStart(i, m.config))
    add(result, m.s[i])
    add(result, genSectionEnd(i, m.config))
    if m.config.cppCustomNamespace.len > 0 and i == cfsHeaders: result.add openNamespaceNim(m.config.cppCustomNamespace)
  add(result, m.s[cfsInitProc])

  if optGenDynLib in m.config.globalOptions:
    result.add("N_LIB_IMPORT ")
  result.addf("N_CDECL(void, NimMain)(void);$n", [])
  if m.config.cppCustomNamespace.len > 0: result.add closeNamespaceNim()
  result.addf("#endif /* $1 */$n", [guard])
  if not writeRope(result, m.filename):
    rawMessage(m.config, errCannotOpenFile, m.filename.string)

proc getCFile(m: BModule): AbsoluteFile =
  let ext =
      if m.compileToCpp: ".cpp"
      elif m.config.cmd == cmdCompileToOC or sfCompileToObjC in m.module.flags: ".m"
      else: ".c"
  result = changeFileExt(completeCFilePath(m.config, withPackageName(m.config, m.cfilename)), ext)

when false:
  proc myOpenCached(graph: ModuleGraph; module: PSym, rd: PRodReader): PPassContext =
    injectG()
    var m = newModule(g, module, graph.config)
    readMergeInfo(getCFile(m), m)
    result = m

proc addHcrInitGuards(p: BProc, n: PNode, inInitGuard: var bool) =
  if n.kind == nkStmtList:
    for child in n:
      addHcrInitGuards(p, child, inInitGuard)
  else:
    let stmtShouldExecute = n.kind in {nkVarSection, nkLetSection} or
                            nfExecuteOnReload in n.flags
    if inInitGuard:
      if stmtShouldExecute:
        endBlock(p)
        inInitGuard = false
    else:
      if not stmtShouldExecute:
        line(p, cpsStmts, "if (nim_hcr_do_init_)\n")
        startBlock(p)
        inInitGuard = true

    genStmts(p, n)

proc myProcess(b: PPassContext, n: PNode): PNode =
  result = n
  if b == nil: return
  var m = BModule(b)
  if passes.skipCodegen(m.config, n): return
  m.initProc.options = initProcOptions(m)
  #softRnl = if optLineDir in m.config.options: noRnl else: rnl
  # XXX replicate this logic!
  let transformed_n = transformStmt(m.g.graph, m.module, n)
  if m.hcrOn:
    addHcrInitGuards(m.initProc, transformed_n, m.inHcrInitGuard)
  else:
    genStmts(m.initProc, transformed_n)

proc shouldRecompile(m: BModule; code: Rope, cfile: Cfile): bool =
  result = true
  if optForceFullMake notin m.config.globalOptions:
    if not equalsFile(code, cfile.cname):
      if m.config.symbolFiles == readOnlySf: #isDefined(m.config, "nimdiff"):
        if fileExists(cfile.cname):
          copyFile(cfile.cname.string, cfile.cname.string & ".backup")
          echo "diff ", cfile.cname.string, ".backup ", cfile.cname.string
        else:
          echo "new file ", cfile.cname.string
      if not writeRope(code, cfile.cname):
        rawMessage(m.config, errCannotOpenFile, cfile.cname.string)
      return
    if fileExists(cfile.obj) and os.fileNewer(cfile.obj.string, cfile.cname.string):
      result = false
  else:
    if not writeRope(code, cfile.cname):
      rawMessage(m.config, errCannotOpenFile, cfile.cname.string)

# We need 2 different logics here: pending modules (including
# 'nim__dat') may require file merging for the combination of dead code
# elimination and incremental compilation! Non pending modules need no
# such logic and in fact the logic hurts for the main module at least;
# it would generate multiple 'main' procs, for instance.

proc writeModule(m: BModule, pending: bool) =
  # generate code for the init statements of the module:
  let cfile = getCFile(m)

  if true or optForceFullMake in m.config.globalOptions:
    genInitCode(m)
    finishTypeDescriptions(m)
    if sfMainModule in m.module.flags:
      # generate main file:
      genMainProc(m)
      add(m.s[cfsProcHeaders], m.g.mainModProcs)
      generateThreadVarsSize(m)

    var cf = Cfile(cname: cfile, obj: completeCFilePath(m.config, toObjFile(m.config, cfile)), flags: {})
    var code = genModule(m, cf)
    if code != nil:
      when hasTinyCBackend:
        if conf.cmd == cmdRun:
          tccgen.compileCCode($code)
          return

      if not shouldRecompile(m, code, cf): cf.flags = {CfileFlag.Cached}
      addFileToCompile(m.config, cf)
  elif pending and mergeRequired(m) and sfMainModule notin m.module.flags:
    let cf = Cfile(cname: cfile, obj: completeCFilePath(m.config, toObjFile(m.config, cfile)), flags: {})
    mergeFiles(cfile, m)
    genInitCode(m)
    finishTypeDescriptions(m)
    var code = genModule(m, cf)
    if code != nil:
      if not writeRope(code, cfile):
        rawMessage(m.config, errCannotOpenFile, cfile.string)
      addFileToCompile(m.config, cf)
  else:
    # Consider: first compilation compiles ``system.nim`` and produces
    # ``system.c`` but then compilation fails due to an error. This means
    # that ``system.o`` is missing, so we need to call the C compiler for it:
    var cf = Cfile(cname: cfile, obj: completeCFilePath(m.config, toObjFile(m.config, cfile)), flags: {})
    if not fileExists(cf.obj): cf.flags = {CfileFlag.Cached}
    addFileToCompile(m.config, cf)
  close(m.ndi)

proc updateCachedModule(m: BModule) =
  let cfile = getCFile(m)
  var cf = Cfile(cname: cfile, obj: completeCFilePath(m.config, toObjFile(m.config, cfile)), flags: {})

  if mergeRequired(m) and sfMainModule notin m.module.flags:
    mergeFiles(cfile, m)
    genInitCode(m)
    finishTypeDescriptions(m)
    var code = genModule(m, cf)
    if code != nil:
      if not writeRope(code, cfile):
        rawMessage(m.config, errCannotOpenFile, cfile.string)
      addFileToCompile(m.config, cf)
  else:
    if sfMainModule notin m.module.flags:
      genMainProc(m)
    cf.flags = {CfileFlag.Cached}
    addFileToCompile(m.config, cf)

proc myClose(graph: ModuleGraph; b: PPassContext, n: PNode): PNode =
  result = n
  if b == nil: return
  var m = BModule(b)
  if passes.skipCodegen(m.config, n): return
  # if the module is cached, we don't regenerate the main proc
  # nor the dispatchers? But if the dispatchers changed?
  # XXX emit the dispatchers into its own .c file?
  if n != nil:
    m.initProc.options = initProcOptions(m)
    genStmts(m.initProc, n)

  if m.hcrOn:
    # make sure this is pulled in (meaning hcrGetGlobal() is called for it during init)
    discard cgsym(m, "programResult")
    if m.inHcrInitGuard:
      endBlock(m.initProc)

  if sfMainModule in m.module.flags:
    if m.hcrOn:
      # pull ("define" since they are inline when HCR is on) these functions in the main file
      # so it can load the HCR runtime and later pass the library handle to the HCR runtime which
      # will in turn pass it to the other modules it initializes so they can initialize the
      # register/get procs so they don't have to have the definitions of these functions as well
      discard cgsym(m, "nimLoadLibrary")
      discard cgsym(m, "nimLoadLibraryError")
      discard cgsym(m, "nimGetProcAddr")
      discard cgsym(m, "procAddrError")
      discard cgsym(m, "rawWrite")

    # raise dependencies on behalf of genMainProc
    if m.config.target.targetOS != osStandalone and m.config.selectedGC != gcNone:
      discard cgsym(m, "initStackBottomWith")
    if emulatedThreadVars(m.config) and m.config.target.targetOS != osStandalone:
      discard cgsym(m, "initThreadVarsEmulation")

    if m.g.breakpoints != nil:
      discard cgsym(m, "dbgRegisterBreakpoint")
    if optEndb in m.config.options:
      discard cgsym(m, "dbgRegisterFilename")

    if m.g.forwardedProcs.len == 0:
      incl m.flags, objHasKidsValid
    let disp = generateMethodDispatchers(graph)
    for x in disp: genProcAux(m, x.sym)

  m.g.modules_closed.add m

proc genForwardedProcs(g: BModuleList) =
  # Forward declared proc:s lack bodies when first encountered, so they're given
  # a second pass here
  # Note: ``genProcNoForward`` may add to ``forwardedProcs``
  while g.forwardedProcs.len > 0:
    let
      prc = g.forwardedProcs.pop()
      ms = getModule(prc)
      m = g.modules[ms.position]
    if sfForward in prc.flags:
      internalError(m.config, prc.info, "still forwarded: " & prc.name.s)

    genProcNoForward(m, prc)

proc cgenWriteModules*(backend: RootRef, config: ConfigRef) =
  let g = BModuleList(backend)
  g.config = config

  # we need to process the transitive closure because recursive module
  # deps are allowed (and the system module is processed in the wrong
  # order anyway)
  genForwardedProcs(g)

  for m in cgenModules(g):
    m.writeModule(pending=true)
  writeMapping(config, g.mapping)
  if g.generatedHeader != nil: writeHeader(g.generatedHeader)

const cgenPass* = makePass(myOpen, myProcess, myClose)
