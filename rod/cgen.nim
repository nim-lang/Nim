#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This is the new C code generator; much cleaner and faster
# than the old one. It also generates better code.

import 
  ast, astalgo, strutils, nhashes, trees, platform, magicsys, extccomp, options, 
  nversion, nimsets, msgs, crc, bitsets, idents, lists, types, ccgutils, os, 
  times, ropes, math, passes, rodread, wordrecg, rnimsyn, treetab, cgmeth

when options.hasTinyCBackend:
  import tccgen

proc cgenPass*(): TPass
# implementation

type 
  TLabel = PRope              # for the C generator a label is just a rope
  TCFileSection = enum        # the sections a generated C file consists of
    cfsHeaders,               # section for C include file headers
    cfsForwardTypes,          # section for C forward typedefs
    cfsTypes,                 # section for C typedefs
    cfsSeqTypes,              # section for sequence types only
                              # this is needed for strange type generation
                              # reasons
    cfsFieldInfo,             # section for field information
    cfsTypeInfo,              # section for type information
    cfsProcHeaders,           # section for C procs prototypes
    cfsData,                  # section for C constant data
    cfsVars,                  # section for C variable declarations
    cfsProcs,                 # section for C procs that are not inline
    cfsTypeInit1,             # section 1 for declarations of type information
    cfsTypeInit2,             # section 2 for init of type information
    cfsTypeInit3,             # section 3 for init of type information
    cfsDebugInit,             # section for init of debug information
    cfsDynLibInit,            # section for init of dynamic library binding
    cfsDynLibDeinit           # section for deinitialization of dynamic libraries
  TCTypeKind = enum           # describes the type kind of a C type
    ctVoid, ctChar, ctBool, ctUInt, ctUInt8, ctUInt16, ctUInt32, ctUInt64, 
    ctInt, ctInt8, ctInt16, ctInt32, ctInt64, ctFloat, ctFloat32, ctFloat64, 
    ctFloat128, ctArray, ctStruct, ctPtr, ctNimStr, ctNimSeq, ctProc, ctCString
  TCFileSections = array[TCFileSection, PRope] # represents a generated C file
  TCProcSection = enum        # the sections a generated C proc consists of
    cpsLocals,                # section of local variables for C proc
    cpsInit,                  # section for init of variables for C proc
    cpsStmts                  # section of local statements for C proc
  TCProcSections = array[TCProcSection, PRope] # represents a generated C proc
  BModule = ref TCGen
  BProc = ref TCProc
  TBlock{.final.} = object 
    id*: int                  # the ID of the label; positive means that it
                              # has been used (i.e. the label should be emitted)
    nestedTryStmts*: int      # how many try statements is it nested into
  
  TCProc{.final.} = object    # represents C proc that is currently generated
    s*: TCProcSections        # the procs sections; short name for readability
    prc*: PSym                # the Nimrod proc that this C proc belongs to
    BeforeRetNeeded*: bool    # true iff 'BeforeRet' label for proc is needed
    nestedTryStmts*: Natural  # in how many nested try statements we are
                              # (the vars must be volatile then)
    labels*: Natural          # for generating unique labels in the C proc
    blocks*: seq[TBlock]      # nested blocks
    options*: TOptions        # options that should be used for code
                              # generation; this is the same as prc.options
                              # unless prc == nil
    frameLen*: int            # current length of frame descriptor
    sendClosure*: PType       # closure record type that we pass
    receiveClosure*: PType    # closure record type that we get
    module*: BModule          # used to prevent excessive parameter passing
  
  TTypeSeq = seq[PType]
  TCGen = object of TPassContext # represents a C source file
    module*: PSym
    filename*: string
    s*: TCFileSections        # sections of the C file
    cfilename*: string        # filename of the module (including path,
                              # without extension)
    typeCache*: TIdTable      # cache the generated types
    forwTypeCache*: TIdTable  # cache for forward declarations of types
    declaredThings*: TIntSet  # things we have declared in this .c file
    declaredProtos*: TIntSet  # prototypes we have declared in this .c file
    headerFiles*: TLinkedList # needed headers to include
    typeInfoMarker*: TIntSet  # needed for generating type information
    initProc*: BProc          # code for init procedure
    typeStack*: TTypeSeq      # used for type generation
    dataCache*: TNodeTable
    forwardedProcs*: TSymSeq  # keep forwarded procs here
    typeNodes*, nimTypes*: int # used for type info generation
    typeNodesName*, nimTypesName*: PRope # used for type info generation
    labels*: natural          # for generating unique module-scope names
  

var 
  mainModProcs, mainModInit: PRope # parts of the main module
  gMapping: PRope             # the generated mapping file (if requested)
  gProcProfile: Natural       # proc profile counter
  gGeneratedSyms: TIntSet     # set of ID's of generated symbols
  gPendingModules: seq[BModule] = @[] # list of modules that are not
                                      # finished with code generation
  gForwardedProcsCounter: int = 0
  gNimDat: BModule            # generated global data

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
  if ms.id == m.module.id: 
    return m
  for i in countup(0, high(gPendingModules)): 
    result = gPendingModules[i]
    if result.module.id == ms.id: return 
  InternalError(s.info, "no pending module found for: " & s.name.s)

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
  
proc newProc(prc: PSym, module: BModule): BProc = 
  new(result)
  result.prc = prc
  result.module = module
  if prc != nil: result.options = prc.options
  else: result.options = gOptions
  result.blocks = @ []

proc isSimpleConst(typ: PType): bool = 
  result = not (skipTypes(typ, abstractVar).kind in
      {tyTuple, tyObject, tyArray, tyArrayConstr, tySet, tySequence})

proc useHeader(m: BModule, sym: PSym) = 
  if lfHeader in sym.loc.Flags: 
    assert(sym.annex != nil)
    discard lists.IncludeStr(m.headerFiles, getStr(sym.annex.path))

proc UseMagic(m: BModule, name: string)

include "ccgtypes.nim"

# ------------------------------ Manager of temporaries ------------------

proc getTemp(p: BProc, t: PType, result: var TLoc) = 
  inc(p.labels)
  if gCmd == cmdCompileToLLVM: 
    result.r = con("%LOC", toRope(p.labels))
  else: 
    result.r = con("LOC", toRope(p.labels))
    appf(p.s[cpsLocals], "$1 $2;$n", [getTypeDesc(p.module, t), result.r])
  result.k = locTemp
  result.a = - 1
  result.t = getUniqueType(t)
  result.s = OnStack
  result.flags = {}

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
  var tmp: PRope
  assert(s.kind == skParam)
  if not (lfParamCopy in s.loc.flags): 
    inc(p.labels)
    tmp = con("%LOC", toRope(p.labels))
    incl(s.loc.flags, lfParamCopy)
    incl(s.loc.flags, lfIndirect)
    appf(p.s[cpsInit], "$1 = alloca $3$n" & "store $3 $2, $3* $1$n", 
         [tmp, s.loc.r, getTypeDesc(p.module, s.loc.t)])
    s.loc.r = tmp

proc localDebugInfo(p: BProc, s: PSym) = 
  var name, a: PRope
  if {optStackTrace, optEndb} * p.options != {optStackTrace, optEndb}: return 
  # XXX work around a bug: No type information for open arrays possible:
  if skipTypes(s.typ, abstractVar).kind == tyOpenArray: return
  if gCmd == cmdCompileToLLVM: 
    # "address" is the 0th field
    # "typ" is the 1rst field
    # "name" is the 2nd field
    name = cstringLit(p, p.s[cpsInit], normalize(s.name.s))
    if (s.kind == skParam) and not ccgIntroducedPtr(s): allocParam(p, s)
    inc(p.labels, 3)
    appf(p.s[cpsInit], "%LOC$6 = getelementptr %TF* %F, %NI 0, $1, %NI 0$n" &
        "%LOC$7 = getelementptr %TF* %F, %NI 0, $1, %NI 1$n" &
        "%LOC$8 = getelementptr %TF* %F, %NI 0, $1, %NI 2$n" &
        "store i8* $2, i8** %LOC$6$n" & "store $3* $4, $3** %LOC$7$n" &
        "store i8* $5, i8** %LOC$8$n", [toRope(p.frameLen), s.loc.r, 
                                        getTypeDesc(p.module, "TNimType"), 
                                        genTypeInfo(p.module, s.loc.t), name, 
                                        toRope(p.labels), toRope(p.labels - 1), 
                                        toRope(p.labels - 2)])
  else: 
    a = con("&", s.loc.r)
    if (s.kind == skParam) and ccgIntroducedPtr(s): a = s.loc.r
    appf(p.s[cpsInit], 
         "F.s[$1].address = (void*)$3; F.s[$1].typ = $4; F.s[$1].name = $2;$n", [
        toRope(p.frameLen), makeCString(normalize(s.name.s)), a, 
        genTypeInfo(p.module, s.loc.t)])
  inc(p.frameLen)

proc assignLocalVar(p: BProc, s: PSym) = 
  #assert(s.loc.k == locNone) // not yet assigned
  # this need not be fullfilled for inline procs; they are regenerated
  # for each module that uses them!
  if s.loc.k == locNone: 
    fillLoc(s.loc, locLocalVar, s.typ, mangleName(s), OnStack)
  if gCmd == cmdCompileToLLVM: 
    appf(p.s[cpsLocals], "$1 = alloca $2$n", 
         [s.loc.r, getTypeDesc(p.module, s.loc.t)])
    incl(s.loc.flags, lfIndirect)
  else: 
    app(p.s[cpsLocals], getTypeDesc(p.module, s.loc.t))
    if sfRegister in s.flags: app(p.s[cpsLocals], " register")
    if (sfVolatile in s.flags) or (p.nestedTryStmts > 0): 
      app(p.s[cpsLocals], " volatile")
    appf(p.s[cpsLocals], " $1;$n", [s.loc.r])
  localDebugInfo(p, s)

proc assignGlobalVar(p: BProc, s: PSym) = 
  if s.loc.k == locNone: 
    fillLoc(s.loc, locGlobalVar, s.typ, mangleName(s), OnHeap)
  if gCmd == cmdCompileToLLVM: 
    appf(p.module.s[cfsVars], "$1 = linkonce global $2 zeroinitializer$n", 
         [s.loc.r, getTypeDesc(p.module, s.loc.t)])
    incl(s.loc.flags, lfIndirect)
  else: 
    useHeader(p.module, s)
    if lfNoDecl in s.loc.flags: return 
    if sfImportc in s.flags: app(p.module.s[cfsVars], "extern ")
    app(p.module.s[cfsVars], getTypeDesc(p.module, s.loc.t))
    if sfRegister in s.flags: app(p.module.s[cfsVars], " register")
    if sfVolatile in s.flags: app(p.module.s[cfsVars], " volatile")
    if sfThreadVar in s.flags: app(p.module.s[cfsVars], " NIM_THREADVAR")
    appf(p.module.s[cfsVars], " $1;$n", [s.loc.r])
  if {optStackTrace, optEndb} * p.module.module.options ==
      {optStackTrace, optEndb}: 
    useMagic(p.module, "dbgRegisterGlobal")
    appff(p.module.s[cfsDebugInit], "dbgRegisterGlobal($1, &$2, $3);$n", 
          "call void @dbgRegisterGlobal(i8* $1, i8* $2, $4* $3)$n", [cstringLit(
        p, p.module.s[cfsDebugInit], normalize(s.owner.name.s & '.' & s.name.s)), 
        s.loc.r, genTypeInfo(p.module, s.typ), getTypeDesc(p.module, "TNimType")])

proc iff(cond: bool, the, els: PRope): PRope = 
  if cond: result = the
  else: result = els
  
proc assignParam(p: BProc, s: PSym) = 
  assert(s.loc.r != nil)
  if (sfAddrTaken in s.flags) and (gCmd == cmdCompileToLLVM): allocParam(p, s)
  localDebugInfo(p, s)

proc fillProcLoc(sym: PSym) = 
  if sym.loc.k == locNone: 
    fillLoc(sym.loc, locProc, sym.typ, mangleName(sym), OnStack)
  
proc getLabel(p: BProc): TLabel = 
  inc(p.labels)
  result = con("LA", toRope(p.labels))

proc fixLabel(p: BProc, labl: TLabel) = 
  appf(p.s[cpsStmts], "$1: ;$n", [labl])

proc genVarPrototype(m: BModule, sym: PSym)
proc genConstPrototype(m: BModule, sym: PSym)
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
    var prefix = copy(s, 0, le - 1)
    var suffix = copy(s, ri + 1)
    for middle in split(copy(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else: 
    add(dest, s)

proc loadDynamicLib(m: BModule, lib: PLib) = 
  assert(lib != nil)
  if not lib.generated: 
    lib.generated = true
    var tmp = getGlobalTempName()
    assert(lib.name == nil)
    lib.name = tmp # BUGFIX: useMagic has awful side-effects
    appf(m.s[cfsVars], "static void* $1;$n", [tmp])
    if lib.path.kind in {nkStrLit..nkTripleStrLit}:
      var s: TStringSeq = @[]
      libCandidates(lib.path.strVal, s)
      var loadlib: PRope = nil
      for i in countup(0, high(s)): 
        inc(m.labels)
        if i > 0: app(loadlib, "||")
        appf(loadlib, "($1 = nimLoadLibrary((NimStringDesc*) &$2))$n", 
             [tmp, getStrLit(m, s[i])])
      appf(m.s[cfsDynLibInit], 
           "if (!($1)) nimLoadLibraryError((NimStringDesc*) &$2);$n", 
           [loadlib, getStrLit(m, lib.path.strVal)]) 
    else:
      var p = newProc(nil, m)
      var dest: TLoc
      initLocExpr(p, lib.path, dest)
      app(m.s[cfsVars], p.s[cpsLocals])
      app(m.s[cfsDynLibInit], p.s[cpsInit])
      app(m.s[cfsDynLibInit], p.s[cpsStmts])
      appf(m.s[cfsDynLibInit], 
           "if (!($1 = nimLoadLibrary($2))) nimLoadLibraryError($2);$n", 
           [tmp, rdLoc(dest)])
      
    useMagic(m, "nimLoadLibrary")
    useMagic(m, "nimUnloadLibrary")
    useMagic(m, "NimStringDesc")
    useMagic(m, "nimLoadLibraryError")
  if lib.name == nil: InternalError("loadDynamicLib")
  
proc SymInDynamicLib(m: BModule, sym: PSym) = 
  var lib = sym.annex
  var extname = sym.loc.r
  loadDynamicLib(m, lib)
  useMagic(m, "nimGetProcAddr")
  if gCmd == cmdCompileToLLVM: incl(sym.loc.flags, lfIndirect)
  var tmp = ropeff("Dl_$1", "@Dl_$1", [toRope(sym.id)])
  sym.loc.r = tmp             # from now on we only need the internal name
  sym.typ.sym = nil           # generate a new name
  inc(m.labels, 2)
  appff(m.s[cfsDynLibInit], 
      "$1 = ($2) nimGetProcAddr($3, $4);$n", "%MOC$5 = load i8* $3$n" &
      "%MOC$6 = call $2 @nimGetProcAddr(i8* %MOC$5, i8* $4)$n" &
      "store $2 %MOC$6, $2* $1$n", [tmp, getTypeDesc(m, sym.typ), 
      lib.name, cstringLit(m, m.s[cfsDynLibInit], ropeToStr(extname)), 
      toRope(m.labels), toRope(m.labels - 1)])
  appff(m.s[cfsVars], "$2 $1;$n", 
      "$1 = linkonce global $2 zeroinitializer$n", 
      [sym.loc.r, getTypeDesc(m, sym.loc.t)])

proc UseMagic(m: BModule, name: string) = 
  var sym = magicsys.getCompilerProc(name)
  if sym != nil: 
    case sym.kind
    of skProc, skMethod, skConverter: genProc(m, sym)
    of skVar: genVarPrototype(m, sym)
    of skType: discard getTypeDesc(m, sym.typ)
    else: InternalError("useMagic: " & name)
  elif not (sfSystemModule in m.module.flags): 
    rawMessage(errSystemNeeds, name) # don't be too picky here
  
proc generateHeaders(m: BModule) = 
  app(m.s[cfsHeaders], "#include \"nimbase.h\"" & tnl & tnl)
  var it = PStrEntry(m.headerFiles.head)
  while it != nil: 
    if not (it.data[0] in {'\"', '<'}): 
      appf(m.s[cfsHeaders], "#include \"$1\"$n", [toRope(it.data)])
    else: 
      appf(m.s[cfsHeaders], "#include $1$n", [toRope(it.data)])
    it = PStrEntry(it.Next)

proc getFrameDecl(p: BProc) = 
  var slots: PRope
  if p.frameLen > 0: 
    useMagic(p.module, "TVarSlot")
    slots = ropeff("  TVarSlot s[$1];$n", ", [$1 x %TVarSlot]", 
                   [toRope(p.frameLen)])
  else: 
    slots = nil
  appff(p.s[cpsLocals], "volatile struct {TFrame* prev;" &
      "NCSTRING procname;NI line;NCSTRING filename;" & 
      "NI len;$n$1} F;$n", 
      "%TF = type {%TFrame*, i8*, %NI, %NI$1}$n" & 
      "%F = alloca %TF$n", [slots])
  inc(p.labels)
  prepend(p.s[cpsInit], ropeff("F.len = $1;$n", 
      "%LOC$2 = getelementptr %TF %F, %NI 4$n" &
      "store %NI $1, %NI* %LOC$2$n", [toRope(p.frameLen), toRope(p.labels)]))

proc retIsNotVoid(s: PSym): bool = 
  result = (s.typ.sons[0] != nil) and not isInvalidReturnType(s.typ.sons[0])

proc initFrame(p: BProc, procname, filename: PRope): PRope = 
  inc(p.labels, 5)
  result = ropeff("F.procname = $1;$n" & "F.prev = framePtr;$n" &
      "F.filename = $2;$n" & "F.line = 0;$n" & "framePtr = (TFrame*)&F;$n", 
      "%LOC$3 = getelementptr %TF %F, %NI 1$n" &
      "%LOC$4 = getelementptr %TF %F, %NI 0$n" &
      "%LOC$5 = getelementptr %TF %F, %NI 3$n" &
      "%LOC$6 = getelementptr %TF %F, %NI 2$n" & "store i8* $1, i8** %LOC$3$n" &
      "store %TFrame* @framePtr, %TFrame** %LOC$4$n" &
      "store i8* $2, i8** %LOC$5$n" & "store %NI 0, %NI* %LOC$6$n" &
      "%LOC$7 = bitcast %TF* %F to %TFrame*$n" &
      "store %TFrame* %LOC$7, %TFrame** @framePtr$n", [procname, filename, 
      toRope(p.labels), toRope(p.labels - 1), toRope(p.labels - 2), 
      toRope(p.labels - 3), toRope(p.labels - 4)])

proc deinitFrame(p: BProc): PRope = 
  inc(p.labels, 3)
  result = ropeff("framePtr = framePtr->prev;$n", 
      "%LOC$1 = load %TFrame* @framePtr$n" &
      "%LOC$2 = getelementptr %TFrame* %LOC$1, %NI 0$n" &
      "%LOC$3 = load %TFrame** %LOC$2$n" &
      "store %TFrame* $LOC$3, %TFrame** @framePtr", [toRope(p.labels), 
      toRope(p.labels - 1), toRope(p.labels - 2)])

proc genProcAux(m: BModule, prc: PSym) = 
  var 
    p: BProc
    generatedProc, header, returnStmt, procname, filename: PRope
    res, param: PSym
  p = newProc(prc, m)
  header = genProcHeader(m, prc)
  if (gCmd != cmdCompileToLLVM) and (lfExportLib in prc.loc.flags): 
    header = con("N_LIB_EXPORT ", header)
  returnStmt = nil
  assert(prc.ast != nil)
  if not (sfPure in prc.flags) and (prc.typ.sons[0] != nil): 
    res = prc.ast.sons[resultPos].sym # get result symbol
    if not isInvalidReturnType(prc.typ.sons[0]): 
      # declare the result symbol:
      assignLocalVar(p, res)
      assert(res.loc.r != nil)
      returnStmt = ropeff("return $1;$n", "ret $1$n", [rdLoc(res.loc)])
    else: 
      fillResult(res)
      assignParam(p, res)
      if skipTypes(res.typ, abstractInst).kind == tyArray: 
        incl(res.loc.flags, lfIndirect)
        res.loc.s = OnUnknown
    initVariable(p, res)
    genObjectInit(p, res.typ, res.loc, true)
  for i in countup(1, sonsLen(prc.typ.n) - 1): 
    param = prc.typ.n.sons[i].sym
    assignParam(p, param)
  genStmts(p, prc.ast.sons[codePos]) # modifies p.locals, p.init, etc.
  if sfPure in prc.flags: 
    generatedProc = ropeff("$1 {$n$2$3$4}$n", "define $1 {$n$2$3$4}$n", [header, 
        p.s[cpsLocals], p.s[cpsInit], p.s[cpsStmts]])
  else: 
    generatedProc = ropeff("$1 {$n", "define $1 {$n", [header])
    if optStackTrace in prc.options: 
      getFrameDecl(p)
      app(generatedProc, p.s[cpsLocals])
      procname = CStringLit(p, generatedProc, 
                            prc.owner.name.s & '.' & prc.name.s)
      filename = CStringLit(p, generatedProc, toFilename(prc.info))
      app(generatedProc, initFrame(p, procname, filename))
    else: 
      app(generatedProc, p.s[cpsLocals])
    if (optProfiler in prc.options) and (gCmd != cmdCompileToLLVM): 
      if gProcProfile >= 64 * 1024: 
        InternalError(prc.info, "too many procedures for profiling")
      useMagic(m, "profileData")
      app(p.s[cpsLocals], "ticks NIM_profilingStart;" & tnl)
      if prc.loc.a < 0: 
        appf(m.s[cfsDebugInit], "profileData[$1].procname = $2;$n", [
            toRope(gProcProfile), 
            makeCString(prc.owner.name.s & '.' & prc.name.s)])
        prc.loc.a = gProcProfile
        inc(gProcProfile)
      prepend(p.s[cpsInit], toRope("NIM_profilingStart = getticks();" & tnl))
    app(generatedProc, p.s[cpsInit])
    app(generatedProc, p.s[cpsStmts])
    if p.beforeRetNeeded: app(generatedProc, "BeforeRet: ;" & tnl)
    if optStackTrace in prc.options: app(generatedProc, deinitFrame(p))
    if (optProfiler in prc.options) and (gCmd != cmdCompileToLLVM): 
      appf(generatedProc, 
          "profileData[$1].total += elapsed(getticks(), NIM_profilingStart);$n", 
           [toRope(prc.loc.a)])
    app(generatedProc, returnStmt)
    app(generatedProc, '}' & tnl)
  app(m.s[cfsProcs], generatedProc)
  
proc genProcPrototype(m: BModule, sym: PSym) = 
  useHeader(m, sym)
  if (lfNoDecl in sym.loc.Flags): return 
  if lfDynamicLib in sym.loc.Flags: 
    if (sym.owner.id != m.module.id) and
        not intSetContainsOrIncl(m.declaredThings, sym.id): 
      appff(m.s[cfsVars], "extern $1 Dl_$2;$n", 
            "@Dl_$2 = linkonce global $1 zeroinitializer$n", 
            [getTypeDesc(m, sym.loc.t), toRope(sym.id)])
      if gCmd == cmdCompileToLLVM: incl(sym.loc.flags, lfIndirect)
  else: 
    if not IntSetContainsOrIncl(m.declaredProtos, sym.id): 
      appf(m.s[cfsProcHeaders], "$1;$n", [genProcHeader(m, sym)])

proc genProcNoForward(m: BModule, prc: PSym) = 
  fillProcLoc(prc)
  useHeader(m, prc)
  genProcPrototype(m, prc)
  if (lfNoDecl in prc.loc.Flags): return 
  if prc.typ.callConv == ccInline: 
    # We add inline procs to the calling module to enable C based inlining.
    # This also means that a check with ``gGeneratedSyms`` is wrong, we need
    # a check for ``m.declaredThings``.
    if not intSetContainsOrIncl(m.declaredThings, prc.id): genProcAux(m, prc)
  elif lfDynamicLib in prc.loc.flags: 
    if not IntSetContainsOrIncl(gGeneratedSyms, prc.id): 
      SymInDynamicLib(findPendingModule(m, prc), prc)
  elif not (sfImportc in prc.flags): 
    if not IntSetContainsOrIncl(gGeneratedSyms, prc.id): 
      genProcAux(findPendingModule(m, prc), prc)
  
proc genProc(m: BModule, prc: PSym) = 
  if sfBorrow in prc.flags: return 
  fillProcLoc(prc)
  if {sfForward, sfFromGeneric} * prc.flags != {}: addForwardedProc(m, prc)
  else: genProcNoForward(m, prc)
  
proc genVarPrototype(m: BModule, sym: PSym) = 
  assert(sfGlobal in sym.flags)
  useHeader(m, sym)
  fillLoc(sym.loc, locGlobalVar, sym.typ, mangleName(sym), OnHeap)
  if (lfNoDecl in sym.loc.Flags) or
      intSetContainsOrIncl(m.declaredThings, sym.id): 
    return 
  if sym.owner.id != m.module.id: 
    # else we already have the symbol generated!
    assert(sym.loc.r != nil)
    if gCmd == cmdCompileToLLVM: 
      incl(sym.loc.flags, lfIndirect)
      appf(m.s[cfsVars], "$1 = linkonce global $2 zeroinitializer$n", 
           [sym.loc.r, getTypeDesc(m, sym.loc.t)])
    else: 
      app(m.s[cfsVars], "extern ")
      app(m.s[cfsVars], getTypeDesc(m, sym.loc.t))
      if sfRegister in sym.flags: app(m.s[cfsVars], " register")
      if sfVolatile in sym.flags: app(m.s[cfsVars], " volatile")
      if sfThreadVar in sym.flags: app(m.s[cfsVars], " NIM_THREADVAR")
      appf(m.s[cfsVars], " $1;$n", [sym.loc.r])

proc genConstPrototype(m: BModule, sym: PSym) = 
  useHeader(m, sym)
  if sym.loc.k == locNone: 
    fillLoc(sym.loc, locData, sym.typ, mangleName(sym), OnUnknown)
  if (lfNoDecl in sym.loc.Flags) or
      intSetContainsOrIncl(m.declaredThings, sym.id): 
    return 
  if sym.owner.id != m.module.id: 
    # else we already have the symbol generated!
    assert(sym.loc.r != nil)
    appff(m.s[cfsData], "extern NIM_CONST $1 $2;$n", 
          "$1 = linkonce constant $2 zeroinitializer", 
          [getTypeDesc(m, sym.loc.t), sym.loc.r])

proc getFileHeader(cfilenoext: string): PRope = 
  if optCompileOnly in gGlobalOptions: 
    result = ropeff("/* Generated by Nimrod Compiler v$1 */$n" &
        "/*   (c) 2010 Andreas Rumpf */$n", 
        "; Generated by Nimrod Compiler v$1$n" &
        ";   (c) 2010 Andreas Rumpf$n", [toRope(versionAsString)])
  else: 
    result = ropeff("/* Generated by Nimrod Compiler v$1 */$n" &
        "/*   (c) 2010 Andreas Rumpf */$n" & "/* Compiled for: $2, $3, $4 */$n" &
        "/* Command for C compiler:$n   $5 */$n", 
        "; Generated by Nimrod Compiler v$1$n" &
        ";   (c) 2010 Andreas Rumpf$n" & "; Compiled for: $2, $3, $4$n" &
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
    CommonMainBody = "  setStackBottom(dummy);$n" & "  nim__datInit();$n" &
        "  systemInit();$n" & "$1" & "$2"
    CommonMainBodyLLVM = "  %MOC$3 = bitcast [8 x %NI]* %dummy to i8*$n" &
        "  call void @setStackBottom(i8* %MOC$3)$n" &
        "  call void @nim__datInit()$n" & "  call void systemInit()$n" & "$1" &
        "$2"
    PosixNimMain = "int cmdCount;$n" & "char** cmdLine;$n" & "char** gEnv;$n" &
        "N_CDECL(void, NimMain)(void) {$n" & "  int dummy[8];$n" &
        CommonMainBody & "}$n"
    PosixCMain = "int main(int argc, char** args, char** env) {$n" &
        "  cmdLine = args;$n" & "  cmdCount = argc;$n" & "  gEnv = env;$n" &
        "  NimMain();$n" & "  return 0;$n" & "}$n"
    PosixNimMainLLVM = "@cmdCount = linkonce i32$n" &
        "@cmdLine = linkonce i8**$n" & "@gEnv = linkonce i8**$n" &
        "define void @NimMain(void) {$n" & "  %dummy = alloca [8 x %NI]$n" &
        CommonMainBodyLLVM & "}$n"
    PosixCMainLLVM = "define i32 @main(i32 %argc, i8** %args, i8** %env) {$n" &
        "  store i8** %args, i8*** @cmdLine$n" &
        "  store i32 %argc, i32* @cmdCount$n" &
        "  store i8** %env, i8*** @gEnv$n" & "  call void @NimMain()$n" &
        "  ret i32 0$n" & "}$n"
    WinNimMain = "N_CDECL(void, NimMain)(void) {$n" & "  int dummy[8];$n" &
        CommonMainBody & "}$n"
    WinCMain = "N_STDCALL(int, WinMain)(HINSTANCE hCurInstance, $n" &
        "                        HINSTANCE hPrevInstance, $n" &
        "                        LPSTR lpCmdLine, int nCmdShow) {$n" &
        "  NimMain();$n" & "  return 0;$n" & "}$n"
    WinNimMainLLVM = "define void @NimMain(void) {$n" &
        "  %dummy = alloca [8 x %NI]$n" & CommonMainBodyLLVM & "}$n"
    WinCMainLLVM = "define stdcall i32 @WinMain(i32 %hCurInstance, $n" &
        "                            i32 %hPrevInstance, $n" &
        "                            i8* %lpCmdLine, i32 %nCmdShow) {$n" &
        "  call void @NimMain()$n" & "  ret i32 0$n" & "}$n"
    WinNimDllMain = "N_LIB_EXPORT N_CDECL(void, NimMain)(void) {$n" &
        "  int dummy[8];$n" & CommonMainBody & "}$n"
    WinCDllMain = "BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fwdreason, $n" &
        "                    LPVOID lpvReserved) {$n" & "  NimMain();$n" &
        "  return 1;$n" & "}$n"
    WinNimDllMainLLVM = WinNimMainLLVM
    WinCDllMainLLVM = 
        "define stdcall i32 @DllMain(i32 %hinstDLL, i32 %fwdreason, $n" &
        "                            i8* %lpvReserved) {$n" &
        "  call void @NimMain()$n" & "  ret i32 1$n" & "}$n"
  var nimMain, otherMain: TFormatStr
  useMagic(m, "setStackBottom")
  if (platform.targetOS == osWindows) and
      (gGlobalOptions * {optGenGuiApp, optGenDynLib} != {}): 
    if optGenGuiApp in gGlobalOptions: 
      if gCmd == cmdCompileToLLVM: 
        nimMain = WinNimMainLLVM
        otherMain = WinCMainLLVM
      else: 
        nimMain = WinNimMain
        otherMain = WinCMain
    else: 
      if gCmd == cmdCompileToLLVM: 
        nimMain = WinNimDllMainLLVM
        otherMain = WinCDllMainLLVM
      else: 
        nimMain = WinNimDllMain
        otherMain = WinCDllMain
    discard lists.IncludeStr(m.headerFiles, "<windows.h>")
  else: 
    if gCmd == cmdCompileToLLVM: 
      nimMain = PosixNimMainLLVM
      otherMain = PosixCMainLLVM
    else: 
      nimMain = PosixNimMain
      otherMain = PosixCMain
  if gBreakpoints != nil: useMagic(m, "dbgRegisterBreakpoint")
  inc(m.labels)
  appf(m.s[cfsProcs], nimMain, [gBreakpoints, mainModInit, toRope(m.labels)])
  if not (optNoMain in gGlobalOptions): appf(m.s[cfsProcs], otherMain, [])
  
proc getInitName(m: PSym): PRope = 
  result = ropeff("$1Init", "@$1Init", [toRope(m.name.s)])

proc registerModuleToMain(m: PSym) = 
  var initname = getInitName(m)
  appff(mainModProcs, "N_NOINLINE(void, $1)(void);$n", 
        "declare void $1() noinline$n", [initname])
  if not (sfSystemModule in m.flags): 
    appff(mainModInit, "$1();$n", "call void ()* $1$n", [initname])
  
proc genInitCode(m: BModule) = 
  var initname, prc, procname, filename: PRope
  if optProfiler in m.initProc.options: 
    # This does not really belong here, but there is no good place for this
    # code. I don't want to put this to the proc generation as the
    # ``IncludeStr`` call is quite slow.
    discard lists.IncludeStr(m.headerFiles, "<cycle.h>")
  initname = getInitName(m.module)
  prc = ropeff("N_NOINLINE(void, $1)(void) {$n", 
               "define void $1() noinline {$n", [initname])
  if m.typeNodes > 0: 
    useMagic(m, "TNimNode")
    appff(m.s[cfsTypeInit1], "static TNimNode $1[$2];$n", 
          "$1 = private alloca [$2 x @TNimNode]$n", 
          [m.typeNodesName, toRope(m.typeNodes)])
  if m.nimTypes > 0: 
    useMagic(m, "TNimType")
    appff(m.s[cfsTypeInit1], "static TNimType $1[$2];$n", 
          "$1 = private alloca [$2 x @TNimType]$n", 
          [m.nimTypesName, toRope(m.nimTypes)])
  if optStackTrace in m.initProc.options: 
    getFrameDecl(m.initProc)
    app(prc, m.initProc.s[cpsLocals])
    app(prc, m.s[cfsTypeInit1])
    procname = CStringLit(m.initProc, prc, "module " & m.module.name.s)
    filename = CStringLit(m.initProc, prc, toFilename(m.module.info))
    app(prc, initFrame(m.initProc, procname, filename))
  else: 
    app(prc, m.initProc.s[cpsLocals])
    app(prc, m.s[cfsTypeInit1])
  app(prc, m.s[cfsTypeInit2])
  app(prc, m.s[cfsTypeInit3])
  app(prc, m.s[cfsDebugInit])
  app(prc, m.s[cfsDynLibInit])
  app(prc, m.initProc.s[cpsInit])
  app(prc, m.initProc.s[cpsStmts])
  if optStackTrace in m.initProc.options: app(prc, deinitFrame(m.initProc))
  app(prc, '}' & tnl & tnl)
  app(m.s[cfsProcs], prc)

proc genModule(m: BModule, cfilenoext: string): PRope = 
  result = getFileHeader(cfilenoext)
  generateHeaders(m)
  for i in countup(low(TCFileSection), cfsProcs): app(result, m.s[i])
  
proc rawNewModule(module: PSym, filename: string): BModule = 
  new(result)
  InitLinkedList(result.headerFiles)
  intSetInit(result.declaredThings)
  intSetInit(result.declaredProtos)
  result.cfilename = filename
  result.filename = filename
  initIdTable(result.typeCache)
  initIdTable(result.forwTypeCache)
  result.module = module
  intSetInit(result.typeInfoMarker)
  result.initProc = newProc(nil, result)
  result.initProc.options = gOptions
  initNodeTable(result.dataCache)
  result.typeStack = @[]
  result.forwardedProcs = @[]
  result.typeNodesName = getTempName()
  result.nimTypesName = getTempName()

proc newModule(module: PSym, filename: string): BModule = 
  result = rawNewModule(module, filename)
  if (optDeadCodeElim in gGlobalOptions): 
    if (sfDeadCodeElim in module.flags): 
      InternalError("added pending module twice: " & filename)
    addPendingModule(result)

proc registerTypeInfoModule() = 
  const moduleName = "nim__dat"
  var s = NewSym(skModule, getIdent(moduleName), nil)
  gNimDat = rawNewModule(s, joinPath(options.projectPath, moduleName) & ".nim")
  addPendingModule(gNimDat)
  appff(mainModProcs, "N_NOINLINE(void, $1)(void);$n", 
        "declare void $1() noinline$n", [getInitName(s)])

proc myOpen(module: PSym, filename: string): PPassContext = 
  if gNimDat == nil: registerTypeInfoModule()
  result = newModule(module, filename)

proc myOpenCached(module: PSym, filename: string, 
                  rd: PRodReader): PPassContext = 
  if gNimDat == nil: 
    registerTypeInfoModule()  
    #MessageOut('cgen.myOpenCached has been called ' + filename);
  var cfile = changeFileExt(completeCFilePath(filename), cExt)
  var cfilenoext = changeFileExt(cfile, "")
  addFileToLink(cfilenoext)
  registerModuleToMain(module) 
  # XXX: this cannot be right here, initalization has to be appended during
  # the ``myClose`` call
  result = nil

proc shouldRecompile(code: PRope, cfile, cfilenoext: string): bool = 
  result = true
  if not (optForceFullMake in gGlobalOptions): 
    var objFile = toObjFile(cfilenoext)
    if writeRopeIfNotEqual(code, cfile): return 
    if ExistsFile(objFile) and os.FileNewer(objFile, cfile): result = false
  else: 
    writeRope(code, cfile)
  
proc myProcess(b: PPassContext, n: PNode): PNode = 
  result = n
  if b == nil: return 
  var m = BModule(b)
  m.initProc.options = gOptions
  genStmts(m.initProc, n)

proc finishModule(m: BModule) = 
  var i = 0
  while i <= high(m.forwardedProcs): 
    # Note: ``genProc`` may add to ``m.forwardedProcs``, so we cannot use
    # a ``for`` loop here
    var prc = m.forwardedProcs[i]
    if sfForward in prc.flags: InternalError(prc.info, "still forwarded")
    genProcNoForward(m, prc)
    inc(i)
  assert(gForwardedProcsCounter >= i)
  dec(gForwardedProcsCounter, i)
  setlen(m.forwardedProcs, 0)

proc writeModule(m: BModule) = 
  # generate code for the init statements of the module:
  genInitCode(m)
  finishTypeDescriptions(m)
  var cfile = completeCFilePath(m.cfilename)
  var cfilenoext = changeFileExt(cfile, "")
  if sfMainModule in m.module.flags: 
    # generate main file:
    app(m.s[cfsProcHeaders], mainModProcs)
  var code = genModule(m, cfilenoext)
  
  when hasTinyCBackend:
    if gCmd == cmdRun:
      tccgen.compileCCode(ropeToStr(code))
      return
  
  if shouldRecompile(code, changeFileExt(cfile, cExt), cfilenoext): 
    addFileToCompile(cfilenoext)
  addFileToLink(cfilenoext)

proc myClose(b: PPassContext, n: PNode): PNode = 
  result = n
  if b == nil: return 
  var m = BModule(b)
  if n != nil: 
    m.initProc.options = gOptions
    genStmts(m.initProc, n)
  registerModuleToMain(m.module)
  if not (optDeadCodeElim in gGlobalOptions) and
      not (sfDeadCodeElim in m.module.flags): 
    finishModule(m)
  if sfMainModule in m.module.flags: 
    var disp = generateMethodDispatchers()
    for i in 0..sonsLen(disp)-1: genProcAux(gNimDat, disp.sons[i].sym)
    genMainProc(m) 
    # we need to process the transitive closure because recursive module
    # deps are allowed (and the system module is processed in the wrong
    # order anyway)
    while gForwardedProcsCounter > 0: 
      for i in countup(0, high(gPendingModules)): 
        finishModule(gPendingModules[i])
    for i in countup(0, high(gPendingModules)): writeModule(gPendingModules[i])
    setlen(gPendingModules, 0)
  if not (optDeadCodeElim in gGlobalOptions) and
      not (sfDeadCodeElim in m.module.flags): 
    writeModule(m)
  if sfMainModule in m.module.flags: writeMapping(gMapping)
  
proc cgenPass(): TPass = 
  initPass(result)
  result.open = myOpen
  result.openCached = myOpenCached
  result.process = myProcess
  result.close = myClose

InitIiTable(gToTypeInfoId)
IntSetInit(gGeneratedSyms)
