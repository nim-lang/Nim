#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

# ------------------------- Name Mangling --------------------------------

import sighashes, modulegraphs

proc genProcHeader(m: BModule, prc: PSym, asPtr: bool = false): Rope

proc isKeyword(w: PIdent): bool =
  # Nim and C++ share some keywords
  # it's more efficient to test the whole Nim keywords range
  case w.id
  of ccgKeywordsLow..ccgKeywordsHigh,
     nimKeywordsLow..nimKeywordsHigh,
     ord(wInline): return true
  else: return false

proc mangleField(m: BModule; name: PIdent): string =
  result = mangle(name.s)
  # fields are tricky to get right and thanks to generic types producing
  # duplicates we can end up mangling the same field multiple times. However
  # if we do so, the 'cppDefines' table might be modified in the meantime
  # meaning we produce inconsistent field names (see bug #5404).
  # Hence we do not check for ``m.g.config.cppDefines.contains(result)`` here
  # anymore:
  if isKeyword(name):
    result.add "_0"

proc mangleName(m: BModule; s: PSym): Rope =
  result = s.loc.r
  if result == nil:
    result = s.name.s.mangle.rope
    result.add "__"
    result.add m.g.graph.ifaces[s.itemId.module].uniqueName
    result.add "_"
    result.add rope s.itemId.item
    if m.hcrOn:
      result.add "_"
      result.add(idOrSig(s, m.module.name.s.mangle, m.sigConflicts, m.config))
    s.loc.r = result
    writeMangledName(m.ndi, s, m.config)

proc mangleParamName(m: BModule; s: PSym): Rope =
  ## we cannot use 'sigConflicts' here since we have a BModule, not a BProc.
  ## Fortunately C's scoping rules are sane enough so that that doesn't
  ## cause any trouble.
  result = s.loc.r
  if result == nil:
    var res = s.name.s.mangle
    # Take into account if HCR is on because of the following scenario:
    #   if a module gets imported and it has some more importc symbols in it,
    # some param names might receive the "_0" suffix to distinguish from what
    # is newly available. That might lead to changes in the C code in nimcache
    # that contain only a parameter name change, but that is enough to mandate
    # recompilation of that source file and thus a new shared object will be
    # relinked. That may lead to a module getting reloaded which wasn't intended
    # and that may be fatal when parts of the current active callstack when
    # performCodeReload() was called are from the module being reloaded
    # unintentionally - example (3 modules which import one another):
    #   main => proxy => reloadable
    # we call performCodeReload() in proxy to reload only changes in reloadable
    # but there is a new import which introduces an importc symbol `socket`
    # and a function called in main or proxy uses `socket` as a parameter name.
    # That would lead to either needing to reload `proxy` or to overwrite the
    # executable file for the main module, which is running (or both!) -> error.
    if m.hcrOn or isKeyword(s.name) or m.g.config.cppDefines.contains(res):
      res.add "_0"
    result = res.rope
    s.loc.r = result
    writeMangledName(m.ndi, s, m.config)

proc mangleLocalName(p: BProc; s: PSym): Rope =
  assert s.kind in skLocalVars+{skTemp}
  #assert sfGlobal notin s.flags
  result = s.loc.r
  if result == nil:
    var key = s.name.s.mangle
    shallow(key)
    let counter = p.sigConflicts.getOrDefault(key)
    result = key.rope
    if s.kind == skTemp:
      # speed up conflict search for temps (these are quite common):
      if counter != 0: result.add "_" & rope(counter+1)
    elif counter != 0 or isKeyword(s.name) or p.module.g.config.cppDefines.contains(key):
      result.add "_" & rope(counter+1)
    p.sigConflicts.inc(key)
    s.loc.r = result
    if s.kind != skTemp: writeMangledName(p.module.ndi, s, p.config)

proc scopeMangledParam(p: BProc; param: PSym) =
  ## parameter generation only takes BModule, not a BProc, so we have to
  ## remember these parameter names are already in scope to be able to
  ## generate unique identifiers reliably (consider that ``var a = a`` is
  ## even an idiom in Nim).
  var key = param.name.s.mangle
  shallow(key)
  p.sigConflicts.inc(key)

const
  irrelevantForBackend = {tyGenericBody, tyGenericInst, tyGenericInvocation,
                          tyDistinct, tyRange, tyStatic, tyAlias, tySink,
                          tyInferred, tyOwned}

proc typeName(typ: PType): Rope =
  let typ = typ.skipTypes(irrelevantForBackend)
  result =
    if typ.sym != nil and typ.kind in {tyObject, tyEnum}:
      rope($typ.kind & '_' & typ.sym.name.s.mangle)
    else:
      rope($typ.kind)

proc getTypeName(m: BModule; typ: PType; sig: SigHash): Rope =
  var t = typ
  while true:
    if t.sym != nil and {sfImportc, sfExportc} * t.sym.flags != {}:
      return t.sym.loc.r

    if t.kind in irrelevantForBackend:
      t = t.lastSon
    else:
      break
  let typ = if typ.kind in {tyAlias, tySink, tyOwned}: typ.lastSon else: typ
  if typ.loc.r == nil:
    typ.loc.r = typ.typeName & $sig
  else:
    when defined(debugSigHashes):
      # check consistency:
      assert($typ.loc.r == $(typ.typeName & $sig))
  result = typ.loc.r
  if result == nil: internalError(m.config, "getTypeName: " & $typ.kind)

proc mapSetType(conf: ConfigRef; typ: PType): TCTypeKind =
  case int(getSize(conf, typ))
  of 1: result = ctInt8
  of 2: result = ctInt16
  of 4: result = ctInt32
  of 8: result = ctInt64
  else: result = ctArray

proc mapType(conf: ConfigRef; typ: PType; kind: TSymKind): TCTypeKind =
  ## Maps a Nim type to a C type
  case typ.kind
  of tyNone, tyTyped: result = ctVoid
  of tyBool: result = ctBool
  of tyChar: result = ctChar
  of tyNil: result = ctPtr
  of tySet: result = mapSetType(conf, typ)
  of tyOpenArray, tyVarargs:
    if kind == skParam: result = ctArray
    else: result = ctStruct
  of tyArray, tyUncheckedArray: result = ctArray
  of tyObject, tyTuple: result = ctStruct
  of tyUserTypeClasses:
    doAssert typ.isResolvedUserTypeClass
    return mapType(conf, typ.lastSon, kind)
  of tyGenericBody, tyGenericInst, tyGenericParam, tyDistinct, tyOrdinal,
     tyTypeDesc, tyAlias, tySink, tyInferred, tyOwned:
    result = mapType(conf, lastSon(typ), kind)
  of tyEnum:
    if firstOrd(conf, typ) < 0:
      result = ctInt32
    else:
      case int(getSize(conf, typ))
      of 1: result = ctUInt8
      of 2: result = ctUInt16
      of 4: result = ctInt32
      of 8: result = ctInt64
      else: result = ctInt32
  of tyRange: result = mapType(conf, typ[0], kind)
  of tyPtr, tyVar, tyLent, tyRef:
    var base = skipTypes(typ.lastSon, typedescInst)
    case base.kind
    of tyOpenArray, tyArray, tyVarargs, tyUncheckedArray: result = ctPtrToArray
    of tySet:
      if mapSetType(conf, base) == ctArray: result = ctPtrToArray
      else: result = ctPtr
    else: result = ctPtr
  of tyPointer: result = ctPtr
  of tySequence: result = ctNimSeq
  of tyProc: result = if typ.callConv != ccClosure: ctProc else: ctStruct
  of tyString: result = ctNimStr
  of tyCstring: result = ctCString
  of tyInt..tyUInt64:
    result = TCTypeKind(ord(typ.kind) - ord(tyInt) + ord(ctInt))
  of tyStatic:
    if typ.n != nil: result = mapType(conf, lastSon typ, kind)
    else: doAssert(false, "mapType: " & $typ.kind)
  else: doAssert(false, "mapType: " & $typ.kind)

proc mapReturnType(conf: ConfigRef; typ: PType): TCTypeKind =
  #if skipTypes(typ, typedescInst).kind == tyArray: result = ctPtr
  #else:
  result = mapType(conf, typ, skResult)

proc isImportedType(t: PType): bool =
  result = t.sym != nil and sfImportc in t.sym.flags

proc isImportedCppType(t: PType): bool =
  let x = t.skipTypes(irrelevantForBackend)
  result = (t.sym != nil and sfInfixCall in t.sym.flags) or
           (x.sym != nil and sfInfixCall in x.sym.flags)

proc getTypeDescAux(m: BModule, origTyp: PType, check: var IntSet; kind: TSymKind): Rope

proc isObjLackingTypeField(typ: PType): bool {.inline.} =
  result = (typ.kind == tyObject) and ((tfFinal in typ.flags) and
      (typ[0] == nil) or isPureObject(typ))

proc isInvalidReturnType(conf: ConfigRef; typ: PType, isProc = true): bool =
  # Arrays and sets cannot be returned by a C procedure, because C is
  # such a poor programming language.
  # We exclude records with refs too. This enhances efficiency and
  # is necessary for proper code generation of assignments.
  var rettype = typ
  var isAllowedCall = true
  if isProc:
    rettype = rettype[0]
    isAllowedCall = typ.callConv in {ccClosure, ccInline, ccNimCall}
  if rettype == nil or (isAllowedCall and
                    getSize(conf, rettype) > conf.target.floatSize*3):
    result = true
  else:
    case mapType(conf, rettype, skResult)
    of ctArray:
      result = not (skipTypes(rettype, typedescInst).kind in
          {tyVar, tyLent, tyRef, tyPtr})
    of ctStruct:
      let t = skipTypes(rettype, typedescInst)
      if rettype.isImportedCppType or t.isImportedCppType: return false
      result = containsGarbageCollectedRef(t) or
          (t.kind == tyObject and not isObjLackingTypeField(t))
    else: result = false

const
  CallingConvToStr: array[TCallingConvention, string] = ["N_NIMCALL",
    "N_STDCALL", "N_CDECL", "N_SAFECALL",
    "N_SYSCALL", # this is probably not correct for all platforms,
                 # but one can #define it to what one wants
    "N_INLINE", "N_NOINLINE", "N_FASTCALL", "N_THISCALL", "N_CLOSURE", "N_NOCONV"]

proc cacheGetType(tab: TypeCache; sig: SigHash): Rope =
  # returns nil if we need to declare this type
  # since types are now unique via the ``getUniqueType`` mechanism, this slow
  # linear search is not necessary anymore:
  result = tab.getOrDefault(sig)

proc addAbiCheck(m: BModule, t: PType, name: Rope) =
  if isDefined(m.config, "checkAbi") and (let size = getSize(m.config, t); size != szUnknownSize):
    var msg = "backend & Nim disagree on size for: "
    msg.addTypeHeader(m.config, t)
    var msg2 = ""
    msg2.addQuoted msg # not a hostspot so extra allocation doesn't matter
    m.s[cfsTypeInfo].addf("NIM_STATIC_ASSERT(sizeof($1) == $2, $3);$n", [name, rope(size), msg2.rope])
    # see `testCodegenABICheck` for example error message it generates


proc fillResult(conf: ConfigRef; param: PNode, proctype: PType) =
  fillLoc(param.sym.loc, locParam, param, ~"Result",
          OnStack)
  let t = param.sym.typ
  if mapReturnType(conf, t) != ctArray and isInvalidReturnType(conf, proctype):
    incl(param.sym.loc.flags, lfIndirect)
    param.sym.loc.storage = OnUnknown

proc typeNameOrLiteral(m: BModule; t: PType, literal: string): Rope =
  if t.sym != nil and sfImportc in t.sym.flags and t.sym.magic == mNone:
    useHeader(m, t.sym)
    result = t.sym.loc.r
  else:
    result = rope(literal)

proc getSimpleTypeDesc(m: BModule, typ: PType): Rope =
  const
    NumericalTypeToStr: array[tyInt..tyUInt64, string] = [
      "NI", "NI8", "NI16", "NI32", "NI64",
      "NF", "NF32", "NF64", "NF128",
      "NU", "NU8", "NU16", "NU32", "NU64"]
  case typ.kind
  of tyPointer:
    result = typeNameOrLiteral(m, typ, "void*")
  of tyString:
    case detectStrVersion(m)
    of 2:
      discard cgsym(m, "NimStrPayload")
      discard cgsym(m, "NimStringV2")
      result = typeNameOrLiteral(m, typ, "NimStringV2")
    else:
      discard cgsym(m, "NimStringDesc")
      result = typeNameOrLiteral(m, typ, "NimStringDesc*")
  of tyCstring: result = typeNameOrLiteral(m, typ, "NCSTRING")
  of tyBool: result = typeNameOrLiteral(m, typ, "NIM_BOOL")
  of tyChar: result = typeNameOrLiteral(m, typ, "NIM_CHAR")
  of tyNil: result = typeNameOrLiteral(m, typ, "void*")
  of tyInt..tyUInt64:
    result = typeNameOrLiteral(m, typ, NumericalTypeToStr[typ.kind])
  of tyDistinct, tyRange, tyOrdinal: result = getSimpleTypeDesc(m, typ[0])
  of tyStatic:
    if typ.n != nil: result = getSimpleTypeDesc(m, lastSon typ)
    else: internalError(m.config, "tyStatic for getSimpleTypeDesc")
  of tyGenericInst, tyAlias, tySink, tyOwned:
    result = getSimpleTypeDesc(m, lastSon typ)
  else: result = nil

  if result != nil and typ.isImportedType():
    let sig = hashType(typ, m.config)
    if cacheGetType(m.typeCache, sig) == nil:
      m.typeCache[sig] = result

proc pushType(m: BModule, typ: PType) =
  for i in 0..high(m.typeStack):
    # pointer equality is good enough here:
    if m.typeStack[i] == typ: return
  m.typeStack.add(typ)

proc getTypePre(m: BModule, typ: PType; sig: SigHash): Rope =
  if typ == nil: result = rope("void")
  else:
    result = getSimpleTypeDesc(m, typ)
    if result == nil: result = cacheGetType(m.typeCache, sig)

proc structOrUnion(t: PType): Rope =
  let cachedUnion = rope("union")
  let cachedStruct = rope("struct")
  let t = t.skipTypes({tyAlias, tySink})
  if tfUnion in t.flags: cachedUnion
  else: cachedStruct

proc addForwardStructFormat(m: BModule, structOrUnion: Rope, typename: Rope) =
  if m.compileToCpp:
    m.s[cfsForwardTypes].addf "$1 $2;$n", [structOrUnion, typename]
  else:
    m.s[cfsForwardTypes].addf "typedef $1 $2 $2;$n", [structOrUnion, typename]

proc seqStar(m: BModule): string =
  if optSeqDestructors in m.config.globalOptions: result = ""
  else: result = "*"

proc getTypeForward(m: BModule, typ: PType; sig: SigHash): Rope =
  result = cacheGetType(m.forwTypeCache, sig)
  if result != nil: return
  result = getTypePre(m, typ, sig)
  if result != nil: return
  let concrete = typ.skipTypes(abstractInst)
  case concrete.kind
  of tySequence, tyTuple, tyObject:
    result = getTypeName(m, typ, sig)
    m.forwTypeCache[sig] = result
    if not isImportedType(concrete):
      addForwardStructFormat(m, structOrUnion(typ), result)
    else:
      pushType(m, concrete)
    doAssert m.forwTypeCache[sig] == result
  else: internalError(m.config, "getTypeForward(" & $typ.kind & ')')

proc getTypeDescWeak(m: BModule; t: PType; check: var IntSet; kind: TSymKind): Rope =
  ## like getTypeDescAux but creates only a *weak* dependency. In other words
  ## we know we only need a pointer to it so we only generate a struct forward
  ## declaration:
  let etB = t.skipTypes(abstractInst)
  case etB.kind
  of tyObject, tyTuple:
    if isImportedCppType(etB) and t.kind == tyGenericInst:
      result = getTypeDescAux(m, t, check, kind)
    else:
      result = getTypeForward(m, t, hashType(t, m.config))
      pushType(m, t)
  of tySequence:
    let sig = hashType(t, m.config)
    if optSeqDestructors in m.config.globalOptions:
      if skipTypes(etB[0], typedescInst).kind == tyEmpty:
        internalError(m.config, "cannot map the empty seq type to a C type")

      result = cacheGetType(m.forwTypeCache, sig)
      if result == nil:
        result = getTypeName(m, t, sig)
        if not isImportedType(t):
          m.forwTypeCache[sig] = result
          addForwardStructFormat(m, rope"struct", result)
          let payload = result & "_Content"
          addForwardStructFormat(m, rope"struct", payload)

      if cacheGetType(m.typeCache, sig) == nil:
        m.typeCache[sig] = result
        #echo "adding ", sig, " ", typeToString(t), " ", m.module.name.s
        appcg(m, m.s[cfsTypes],
          "struct $1 {$N" &
          "  NI len; $1_Content* p;$N" &
          "};$N", [result])
    else:
      result = getTypeForward(m, t, sig) & seqStar(m)
    pushType(m, t)
  else:
    result = getTypeDescAux(m, t, check, kind)

proc getSeqPayloadType(m: BModule; t: PType): Rope =
  var check = initIntSet()
  result = getTypeDescWeak(m, t, check, skParam) & "_Content"
  #result = getTypeForward(m, t, hashType(t)) & "_Content"

proc seqV2ContentType(m: BModule; t: PType; check: var IntSet) =
  let sig = hashType(t, m.config)
  let result = cacheGetType(m.typeCache, sig)
  if result == nil:
    discard getTypeDescAux(m, t, check, skVar)
  else:
    # little hack for now to prevent multiple definitions of the same
    # Seq_Content:
    appcg(m, m.s[cfsTypes], """$N
$3ifndef $2_Content_PP
$3define $2_Content_PP
struct $2_Content { NI cap; $1 data[SEQ_DECL_SIZE];};
$3endif$N
      """, [getTypeDescAux(m, t.skipTypes(abstractInst)[0], check, skVar), result, rope"#"])

proc paramStorageLoc(param: PSym): TStorageLoc =
  if param.typ.skipTypes({tyVar, tyLent, tyTypeDesc}).kind notin {
          tyArray, tyOpenArray, tyVarargs}:
    result = OnStack
  else:
    result = OnUnknown

proc genProcParams(m: BModule, t: PType, rettype, params: var Rope,
                   check: var IntSet, declareEnvironment=true;
                   weakDep=false) =
  params = nil
  if t[0] == nil or isInvalidReturnType(m.config, t):
    rettype = ~"void"
  else:
    rettype = getTypeDescAux(m, t[0], check, skResult)
  for i in 1..<t.n.len:
    if t.n[i].kind != nkSym: internalError(m.config, t.n.info, "genProcParams")
    var param = t.n[i].sym
    if isCompileTimeOnly(param.typ): continue
    if params != nil: params.add(~", ")
    fillLoc(param.loc, locParam, t.n[i], mangleParamName(m, param),
            param.paramStorageLoc)
    if ccgIntroducedPtr(m.config, param, t[0]):
      params.add(getTypeDescWeak(m, param.typ, check, skParam))
      params.add(~"*")
      incl(param.loc.flags, lfIndirect)
      param.loc.storage = OnUnknown
    elif weakDep:
      params.add(getTypeDescWeak(m, param.typ, check, skParam))
    else:
      params.add(getTypeDescAux(m, param.typ, check, skParam))
    params.add(~" ")
    if sfNoalias in param.flags:
      params.add(~"NIM_NOALIAS ")
    params.add(param.loc.r)
    # declare the len field for open arrays:
    var arr = param.typ.skipTypes({tyGenericInst})
    if arr.kind in {tyVar, tyLent, tySink}: arr = arr.lastSon
    var j = 0
    while arr.kind in {tyOpenArray, tyVarargs}:
      # this fixes the 'sort' bug:
      if param.typ.kind in {tyVar, tyLent}: param.loc.storage = OnUnknown
      # need to pass hidden parameter:
      params.addf(", NI $1Len_$2", [param.loc.r, j.rope])
      inc(j)
      arr = arr[0].skipTypes({tySink})
  if t[0] != nil and isInvalidReturnType(m.config, t):
    var arr = t[0]
    if params != nil: params.add(", ")
    if mapReturnType(m.config, t[0]) != ctArray:
      if isHeaderFile in m.flags:
        # still generates types for `--header`
        params.add(getTypeDescAux(m, arr, check, skResult))
        params.add("*")
      else:
        params.add(getTypeDescWeak(m, arr, check, skResult))
        params.add("*")
    else:
      params.add(getTypeDescAux(m, arr, check, skResult))
    params.addf(" Result", [])
  if t.callConv == ccClosure and declareEnvironment:
    if params != nil: params.add(", ")
    params.add("void* ClE_0")
  if tfVarargs in t.flags:
    if params != nil: params.add(", ")
    params.add("...")
  if params == nil: params.add("void)")
  else: params.add(")")
  params = "(" & params

proc mangleRecFieldName(m: BModule; field: PSym): Rope =
  if {sfImportc, sfExportc} * field.flags != {}:
    result = field.loc.r
  else:
    result = rope(mangleField(m, field.name))
  if result == nil: internalError(m.config, field.info, "mangleRecFieldName")

proc genRecordFieldsAux(m: BModule, n: PNode,
                        rectype: PType,
                        check: var IntSet, unionPrefix = ""): Rope =
  result = nil
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      result.add(genRecordFieldsAux(m, n[i], rectype, check, unionPrefix))
  of nkRecCase:
    if n[0].kind != nkSym: internalError(m.config, n.info, "genRecordFieldsAux")
    result.add(genRecordFieldsAux(m, n[0], rectype, check, unionPrefix))
    # prefix mangled name with "_U" to avoid clashes with other field names,
    # since identifiers are not allowed to start with '_'
    var unionBody: Rope = nil
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        let k = lastSon(n[i])
        if k.kind != nkSym:
          let structName = "_" & mangleRecFieldName(m, n[0].sym) & "_" & $i
          let a = genRecordFieldsAux(m, k, rectype, check, unionPrefix & $structName & ".")
          if a != nil:
            if tfPacked notin rectype.flags:
              unionBody.add("struct {")
            else:
              if hasAttribute in CC[m.config.cCompiler].props:
                unionBody.add("struct __attribute__((__packed__)){")
              else:
                unionBody.addf("#pragma pack(push, 1)$nstruct{", [])
            unionBody.add(a)
            unionBody.addf("} $1;$n", [structName])
            if tfPacked in rectype.flags and hasAttribute notin CC[m.config.cCompiler].props:
              unionBody.addf("#pragma pack(pop)$n", [])
        else:
          unionBody.add(genRecordFieldsAux(m, k, rectype, check, unionPrefix))
      else: internalError(m.config, "genRecordFieldsAux(record case branch)")
    if unionBody != nil:
      result.addf("union{$n$1};$n", [unionBody])
  of nkSym:
    let field = n.sym
    if field.typ.kind == tyVoid: return
    #assert(field.ast == nil)
    let sname = mangleRecFieldName(m, field)
    fillLoc(field.loc, locField, n, unionPrefix & sname, OnUnknown)
    if field.alignment > 0:
      result.addf "NIM_ALIGN($1) ", [rope(field.alignment)]
    # for importcpp'ed objects, we only need to set field.loc, but don't
    # have to recurse via 'getTypeDescAux'. And not doing so prevents problems
    # with heavily templatized C++ code:
    if not isImportedCppType(rectype):
      let noAlias = if sfNoalias in field.flags: ~" NIM_NOALIAS" else: nil

      let fieldType = field.loc.lode.typ.skipTypes(abstractInst)
      if fieldType.kind == tyUncheckedArray:
        result.addf("$1 $2[SEQ_DECL_SIZE];$n",
            [getTypeDescAux(m, fieldType.elemType, check, skField), sname])
      elif fieldType.kind == tySequence:
        # we need to use a weak dependency here for trecursive_table.
        result.addf("$1$3 $2;$n", [getTypeDescWeak(m, field.loc.t, check, skField), sname, noAlias])
      elif field.bitsize != 0:
        result.addf("$1$4 $2:$3;$n", [getTypeDescAux(m, field.loc.t, check, skField), sname, rope($field.bitsize), noAlias])
      else:
        # don't use fieldType here because we need the
        # tyGenericInst for C++ template support
        result.addf("$1$3 $2;$n", [getTypeDescAux(m, field.loc.t, check, skField), sname, noAlias])
  else: internalError(m.config, n.info, "genRecordFieldsAux()")

proc getRecordFields(m: BModule, typ: PType, check: var IntSet): Rope =
  result = genRecordFieldsAux(m, typ.n, typ, check)

proc fillObjectFields*(m: BModule; typ: PType) =
  # sometimes generic objects are not consistently merged. We patch over
  # this fact here.
  var check = initIntSet()
  discard getRecordFields(m, typ, check)

proc mangleDynLibProc(sym: PSym): Rope

proc getRecordDesc(m: BModule, typ: PType, name: Rope,
                   check: var IntSet): Rope =
  # declare the record:
  var hasField = false

  if tfPacked in typ.flags:
    if hasAttribute in CC[m.config.cCompiler].props:
      result = structOrUnion(typ) & " __attribute__((__packed__))"
    else:
      result = "#pragma pack(push, 1)\L" & structOrUnion(typ)
  else:
    result = structOrUnion(typ)

  result.add " "
  result.add name

  if typ.kind == tyObject:
    if typ[0] == nil:
      if lacksMTypeField(typ):
        appcg(m, result, " {$n", [])
      else:
        if optTinyRtti in m.config.globalOptions:
          appcg(m, result, " {$n#TNimTypeV2* m_type;$n", [])
        else:
          appcg(m, result, " {$n#TNimType* m_type;$n", [])
        hasField = true
    elif m.compileToCpp:
      appcg(m, result, " : public $1 {$n",
                      [getTypeDescAux(m, typ[0].skipTypes(skipPtrs), check, skField)])
      if typ.isException and m.config.exc == excCpp:
        when false:
          appcg(m, result, "virtual void raise() { throw *this; }$n", []) # required for polymorphic exceptions
          if typ.sym.magic == mException:
            # Add cleanup destructor to Exception base class
            appcg(m, result, "~$1();$n", [name])
            # define it out of the class body and into the procs section so we don't have to
            # artificially forward-declare popCurrentExceptionEx (very VERY troublesome for HCR)
            appcg(m, cfsProcs, "inline $1::~$1() {if(this->raiseId) #popCurrentExceptionEx(this->raiseId);}$n", [name])
      hasField = true
    else:
      appcg(m, result, " {$n  $1 Sup;$n",
                      [getTypeDescAux(m, typ[0].skipTypes(skipPtrs), check, skField)])
      hasField = true
  else:
    result.addf(" {$n", [name])

  let desc = getRecordFields(m, typ, check)
  if desc == nil and not hasField:
    result.addf("char dummy;$n", [])
  else:
    result.add(desc)
  result.add("};\L")
  if tfPacked in typ.flags and hasAttribute notin CC[m.config.cCompiler].props:
    result.add "#pragma pack(pop)\L"

proc getTupleDesc(m: BModule, typ: PType, name: Rope,
                  check: var IntSet): Rope =
  result = "$1 $2 {$n" % [structOrUnion(typ), name]
  var desc: Rope = nil
  for i in 0..<typ.len:
    desc.addf("$1 Field$2;$n",
         [getTypeDescAux(m, typ[i], check, skField), rope(i)])
  if desc == nil: result.add("char dummy;\L")
  else: result.add(desc)
  result.add("};\L")

proc scanCppGenericSlot(pat: string, cursor, outIdx, outStars: var int): bool =
  # A helper proc for handling cppimport patterns, involving numeric
  # placeholders for generic types (e.g. '0, '**2, etc).
  # pre: the cursor must be placed at the ' symbol
  # post: the cursor will be placed after the final digit
  # false will returned if the input is not recognized as a placeholder
  inc cursor
  let begin = cursor
  while pat[cursor] == '*': inc cursor
  if pat[cursor] in Digits:
    outIdx = pat[cursor].ord - '0'.ord
    outStars = cursor - begin
    inc cursor
    return true
  else:
    return false

proc resolveStarsInCppType(typ: PType, idx, stars: int): PType =
  # Make sure the index refers to one of the generic params of the type.
  # XXX: we should catch this earlier and report it as a semantic error.
  if idx >= typ.len:
    doAssert false, "invalid apostrophe type parameter index"

  result = typ[idx]
  for i in 1..stars:
    if result != nil and result.len > 0:
      result = if result.kind == tyGenericInst: result[1]
               else: result.elemType

proc getOpenArrayDesc(m: BModule, t: PType, check: var IntSet; kind: TSymKind): Rope =
  let sig = hashType(t, m.config)
  if kind == skParam:
    result = getTypeDescWeak(m, t[0], check, kind) & "*"
  else:
    result = cacheGetType(m.typeCache, sig)
    if result == nil:
      result = getTypeName(m, t, sig)
      m.typeCache[sig] = result
      let elemType = getTypeDescWeak(m, t[0], check, kind)
      m.s[cfsTypes].addf("typedef struct {$n$2* Field0;$nNI Field1;$n} $1;$n",
                         [result, elemType])

proc getTypeDescAux(m: BModule, origTyp: PType, check: var IntSet; kind: TSymKind): Rope =
  # returns only the type's name

  var t = origTyp.skipTypes(irrelevantForBackend-{tyOwned})
  if containsOrIncl(check, t.id):
    if not (isImportedCppType(origTyp) or isImportedCppType(t)):
      internalError(m.config, "cannot generate C type for: " & typeToString(origTyp))
    # XXX: this BUG is hard to fix -> we need to introduce helper structs,
    # but determining when this needs to be done is hard. We should split
    # C type generation into an analysis and a code generation phase somehow.
  if t.sym != nil: useHeader(m, t.sym)
  if t != origTyp and origTyp.sym != nil: useHeader(m, origTyp.sym)
  let sig = hashType(origTyp, m.config)

  defer: # defer is the simplest in this case
    if isImportedType(t) and not m.typeABICache.containsOrIncl(sig):
      addAbiCheck(m, t, result)

  result = getTypePre(m, t, sig)
  if result != nil and t.kind != tyOpenArray:
    excl(check, t.id)
    return
  case t.kind
  of tyRef, tyPtr, tyVar, tyLent:
    var star = if t.kind in {tyVar} and tfVarIsPtr notin origTyp.flags and
                    compileToCpp(m): "&" else: "*"
    var et = origTyp.skipTypes(abstractInst).lastSon
    var etB = et.skipTypes(abstractInst)
    if mapType(m.config, t, kind) == ctPtrToArray and (etB.kind != tyOpenArray or kind == skParam):
      if etB.kind == tySet:
        et = getSysType(m.g.graph, unknownLineInfo, tyUInt8)
      else:
        et = elemType(etB)
      etB = et.skipTypes(abstractInst)
      star[0] = '*'
    case etB.kind
    of tyObject, tyTuple:
      if isImportedCppType(etB) and et.kind == tyGenericInst:
        result = getTypeDescAux(m, et, check, kind) & star
      else:
        # no restriction! We have a forward declaration for structs
        let name = getTypeForward(m, et, hashType(et, m.config))
        result = name & star
        m.typeCache[sig] = result
    of tySequence:
      if optSeqDestructors in m.config.globalOptions:
        result = getTypeDescWeak(m, et, check, kind) & star
        m.typeCache[sig] = result
      else:
        # no restriction! We have a forward declaration for structs
        let name = getTypeForward(m, et, hashType(et, m.config))
        result = name & seqStar(m) & star
        m.typeCache[sig] = result
        pushType(m, et)
    else:
      # else we have a strong dependency  :-(
      result = getTypeDescAux(m, et, check, kind) & star
      m.typeCache[sig] = result
  of tyOpenArray, tyVarargs:
    result = getOpenArrayDesc(m, t, check, kind)
  of tyEnum:
    result = cacheGetType(m.typeCache, sig)
    if result == nil:
      result = getTypeName(m, origTyp, sig)
      if not (isImportedCppType(t) or
          (sfImportc in t.sym.flags and t.sym.magic == mNone)):
        m.typeCache[sig] = result
        var size: int
        if firstOrd(m.config, t) < 0:
          m.s[cfsTypes].addf("typedef NI32 $1;$n", [result])
          size = 4
        else:
          size = int(getSize(m.config, t))
          case size
          of 1: m.s[cfsTypes].addf("typedef NU8 $1;$n", [result])
          of 2: m.s[cfsTypes].addf("typedef NU16 $1;$n", [result])
          of 4: m.s[cfsTypes].addf("typedef NI32 $1;$n", [result])
          of 8: m.s[cfsTypes].addf("typedef NI64 $1;$n", [result])
          else: internalError(m.config, t.sym.info, "getTypeDescAux: enum")
        when false:
          let owner = hashOwner(t.sym)
          if not gDebugInfo.hasEnum(t.sym.name.s, t.sym.info.line, owner):
            var vals: seq[(string, int)] = @[]
            for i in 0..<t.n.len:
              assert(t.n[i].kind == nkSym)
              let field = t.n[i].sym
              vals.add((field.name.s, field.position.int))
            gDebugInfo.registerEnum(EnumDesc(size: size, owner: owner, id: t.sym.id,
              name: t.sym.name.s, values: vals))
  of tyProc:
    result = getTypeName(m, origTyp, sig)
    m.typeCache[sig] = result
    var rettype, desc: Rope
    genProcParams(m, t, rettype, desc, check, true, true)
    if not isImportedType(t):
      if t.callConv != ccClosure: # procedure vars may need a closure!
        m.s[cfsTypes].addf("typedef $1_PTR($2, $3) $4;$n",
             [rope(CallingConvToStr[t.callConv]), rettype, result, desc])
      else:
        m.s[cfsTypes].addf("typedef struct {$n" &
            "N_NIMCALL_PTR($2, ClP_0) $3;$n" &
            "void* ClE_0;$n} $1;$n",
             [result, rettype, desc])
  of tySequence:
    if optSeqDestructors in m.config.globalOptions:
      result = getTypeDescWeak(m, t, check, kind)
    else:
      # we cannot use getTypeForward here because then t would be associated
      # with the name of the struct, not with the pointer to the struct:
      result = cacheGetType(m.forwTypeCache, sig)
      if result == nil:
        result = getTypeName(m, origTyp, sig)
        if not isImportedType(t):
          addForwardStructFormat(m, structOrUnion(t), result)
        m.forwTypeCache[sig] = result
      assert(cacheGetType(m.typeCache, sig) == nil)
      m.typeCache[sig] = result & seqStar(m)
      if not isImportedType(t):
        if skipTypes(t[0], typedescInst).kind != tyEmpty:
          const
            cppSeq = "struct $2 : #TGenericSeq {$n"
            cSeq = "struct $2 {$n" &
                  "  #TGenericSeq Sup;$n"
          if m.compileToCpp:
            appcg(m, m.s[cfsSeqTypes],
                cppSeq & "  $1 data[SEQ_DECL_SIZE];$n" &
                "};$n", [getTypeDescAux(m, t[0], check, kind), result])
          else:
            appcg(m, m.s[cfsSeqTypes],
                cSeq & "  $1 data[SEQ_DECL_SIZE];$n" &
                "};$n", [getTypeDescAux(m, t[0], check, kind), result])
        else:
          result = rope("TGenericSeq")
      result.add(seqStar(m))
  of tyUncheckedArray:
    result = getTypeName(m, origTyp, sig)
    m.typeCache[sig] = result
    if not isImportedType(t):
      let foo = getTypeDescAux(m, t[0], check, kind)
      m.s[cfsTypes].addf("typedef $1 $2[1];$n", [foo, result])
  of tyArray:
    var n: BiggestInt = toInt64(lengthOrd(m.config, t))
    if n <= 0: n = 1   # make an array of at least one element
    result = getTypeName(m, origTyp, sig)
    m.typeCache[sig] = result
    if not isImportedType(t):
      let foo = getTypeDescAux(m, t[1], check, kind)
      m.s[cfsTypes].addf("typedef $1 $2[$3];$n",
           [foo, result, rope(n)])
  of tyObject, tyTuple:
    if isImportedCppType(t) and origTyp.kind == tyGenericInst:
      let cppName = getTypeName(m, t, sig)
      var i = 0
      var chunkStart = 0

      template addResultType(ty: untyped) =
        if ty == nil or ty.kind == tyVoid:
          result.add(~"void")
        elif ty.kind == tyStatic:
          internalAssert m.config, ty.n != nil
          result.add ty.n.renderTree
        else:
          result.add getTypeDescAux(m, ty, check, kind)

      while i < cppName.data.len:
        if cppName.data[i] == '\'':
          var chunkEnd = i-1
          var idx, stars: int
          if scanCppGenericSlot(cppName.data, i, idx, stars):
            result.add cppName.data.substr(chunkStart, chunkEnd)
            chunkStart = i

            let typeInSlot = resolveStarsInCppType(origTyp, idx + 1, stars)
            addResultType(typeInSlot)
        else:
          inc i

      if chunkStart != 0:
        result.add cppName.data.substr(chunkStart)
      else:
        result = cppName & "<"
        for i in 1..<origTyp.len-1:
          if i > 1: result.add(" COMMA ")
          addResultType(origTyp[i])
        result.add("> ")
      # always call for sideeffects:
      assert t.kind != tyTuple
      discard getRecordDesc(m, t, result, check)
      # The resulting type will include commas and these won't play well
      # with the C macros for defining procs such as N_NIMCALL. We must
      # create a typedef for the type and use it in the proc signature:
      let typedefName = ~"TY" & $sig
      m.s[cfsTypes].addf("typedef $1 $2;$n", [result, typedefName])
      m.typeCache[sig] = typedefName
      result = typedefName
    else:
      result = cacheGetType(m.forwTypeCache, sig)
      if result == nil:
        result = getTypeName(m, origTyp, sig)
        m.forwTypeCache[sig] = result
        if not isImportedType(t):
          addForwardStructFormat(m, structOrUnion(t), result)
        assert m.forwTypeCache[sig] == result
      m.typeCache[sig] = result # always call for sideeffects:
      if not incompleteType(t):
        let recdesc = if t.kind != tyTuple: getRecordDesc(m, t, result, check)
                      else: getTupleDesc(m, t, result, check)
        if not isImportedType(t):
          m.s[cfsTypes].add(recdesc)
        elif tfIncompleteStruct notin t.flags:
          discard # addAbiCheck(m, t, result) # already handled elsewhere
  of tySet:
    # Don't use the imported name as it may be scoped: 'Foo::SomeKind'
    result = $t.kind & '_' & t.lastSon.typeName & $t.lastSon.hashType(m.config)
    m.typeCache[sig] = result
    if not isImportedType(t):
      let s = int(getSize(m.config, t))
      case s
      of 1, 2, 4, 8: m.s[cfsTypes].addf("typedef NU$2 $1;$n", [result, rope(s*8)])
      else: m.s[cfsTypes].addf("typedef NU8 $1[$2];$n",
             [result, rope(getSize(m.config, t))])
  of tyGenericInst, tyDistinct, tyOrdinal, tyTypeDesc, tyAlias, tySink, tyOwned,
     tyUserTypeClass, tyUserTypeClassInst, tyInferred:
    result = getTypeDescAux(m, lastSon(t), check, kind)
  else:
    internalError(m.config, "getTypeDescAux(" & $t.kind & ')')
    result = nil
  # fixes bug #145:
  excl(check, t.id)

proc getTypeDesc(m: BModule, typ: PType; kind = skParam): Rope =
  var check = initIntSet()
  result = getTypeDescAux(m, typ, check, kind)

type
  TClosureTypeKind = enum ## In C closures are mapped to 3 different things.
    clHalf,           ## fn(args) type without the trailing 'void* env' parameter
    clHalfWithEnv,    ## fn(args, void* env) type with trailing 'void* env' parameter
    clFull            ## struct {fn(args, void* env), env}

proc getClosureType(m: BModule, t: PType, kind: TClosureTypeKind): Rope =
  assert t.kind == tyProc
  var check = initIntSet()
  result = getTempName(m)
  var rettype, desc: Rope
  genProcParams(m, t, rettype, desc, check, declareEnvironment=kind != clHalf)
  if not isImportedType(t):
    if t.callConv != ccClosure or kind != clFull:
      m.s[cfsTypes].addf("typedef $1_PTR($2, $3) $4;$n",
           [rope(CallingConvToStr[t.callConv]), rettype, result, desc])
    else:
      m.s[cfsTypes].addf("typedef struct {$n" &
          "N_NIMCALL_PTR($2, ClP_0) $3;$n" &
          "void* ClE_0;$n} $1;$n",
           [result, rettype, desc])

proc finishTypeDescriptions(m: BModule) =
  var i = 0
  var check = initIntSet()
  while i < m.typeStack.len:
    let t = m.typeStack[i]
    if optSeqDestructors in m.config.globalOptions and t.skipTypes(abstractInst).kind == tySequence:
      seqV2ContentType(m, t, check)
    else:
      discard getTypeDescAux(m, t, check, skParam)
    inc(i)
  m.typeStack.setLen 0

template cgDeclFrmt*(s: PSym): string =
  s.constraint.strVal

proc isReloadable(m: BModule, prc: PSym): bool =
  return m.hcrOn and sfNonReloadable notin prc.flags

proc isNonReloadable(m: BModule, prc: PSym): bool =
  return m.hcrOn and sfNonReloadable in prc.flags

proc genProcHeader(m: BModule, prc: PSym, asPtr: bool = false): Rope =
  var
    rettype, params: Rope
  # using static is needed for inline procs
  if lfExportLib in prc.loc.flags:
    if isHeaderFile in m.flags:
      result.add "N_LIB_IMPORT "
    else:
      result.add "N_LIB_EXPORT "
  elif prc.typ.callConv == ccInline or asPtr or isNonReloadable(m, prc):
    result.add "static "
  elif sfImportc notin prc.flags:
    result.add "N_LIB_PRIVATE "
  var check = initIntSet()
  fillLoc(prc.loc, locProc, prc.ast[namePos], mangleName(m, prc), OnUnknown)
  genProcParams(m, prc.typ, rettype, params, check)
  # handle the 2 options for hotcodereloading codegen - function pointer
  # (instead of forward declaration) or header for function body with "_actual" postfix
  let asPtrStr = rope(if asPtr: "_PTR" else: "")
  var name = prc.loc.r
  if isReloadable(m, prc) and not asPtr:
    name.add("_actual")
  # careful here! don't access ``prc.ast`` as that could reload large parts of
  # the object graph!
  if prc.constraint.isNil:
    result.addf("$1$2($3, $4)$5",
         [rope(CallingConvToStr[prc.typ.callConv]), asPtrStr, rettype, name,
         params])
  else:
    let asPtrStr = if asPtr: (rope("(*") & name & ")") else: name
    result = runtimeFormat(prc.cgDeclFrmt, [rettype, asPtrStr, params])

# ------------------ type info generation -------------------------------------

proc genTypeInfoV1(m: BModule, t: PType; info: TLineInfo): Rope
proc getNimNode(m: BModule): Rope =
  result = "$1[$2]" % [m.typeNodesName, rope(m.typeNodes)]
  inc(m.typeNodes)

proc tiNameForHcr(m: BModule, name: Rope): Rope =
  return if m.hcrOn: "(*".rope & name & ")" else: name

proc genTypeInfoAuxBase(m: BModule; typ, origType: PType;
                        name, base: Rope; info: TLineInfo) =
  var nimtypeKind: int
  #allocMemTI(m, typ, name)
  if isObjLackingTypeField(typ):
    nimtypeKind = ord(tyPureObject)
  else:
    nimtypeKind = ord(typ.kind)

  let nameHcr = tiNameForHcr(m, name)

  var size: Rope
  if tfIncompleteStruct in typ.flags:
    size = rope"void*"
  else:
    size = getTypeDesc(m, origType, skVar)
  m.s[cfsTypeInit3].addf(
    "$1.size = sizeof($2);$n$1.align = NIM_ALIGNOF($2);$n$1.kind = $3;$n$1.base = $4;$n",
    [nameHcr, size, rope(nimtypeKind), base]
  )
  # compute type flags for GC optimization
  var flags = 0
  if not containsGarbageCollectedRef(typ): flags = flags or 1
  if not canFormAcycle(m.g.graph, typ): flags = flags or 2
  #else echo("can contain a cycle: " & typeToString(typ))
  if flags != 0:
    m.s[cfsTypeInit3].addf("$1.flags = $2;$n", [nameHcr, rope(flags)])
  discard cgsym(m, "TNimType")
  if isDefined(m.config, "nimTypeNames"):
    var typename = typeToString(if origType.typeInst != nil: origType.typeInst
                                else: origType, preferName)
    if typename == "ref object" and origType.skipTypes(skipPtrs).sym != nil:
      typename = "anon ref object from " & m.config$origType.skipTypes(skipPtrs).sym.info
    m.s[cfsTypeInit3].addf("$1.name = $2;$n",
        [nameHcr, makeCString typename])
    discard cgsym(m, "nimTypeRoot")
    m.s[cfsTypeInit3].addf("$1.nextType = nimTypeRoot; nimTypeRoot=&$1;$n",
         [nameHcr])

  if m.hcrOn:
    m.s[cfsData].addf("static TNimType* $1;$n", [name])
    m.hcrCreateTypeInfosProc.addf("\thcrRegisterGlobal($2, \"$1\", sizeof(TNimType), NULL, (void**)&$1);$n",
         [name, getModuleDllPath(m, m.module)])
  else:
    m.s[cfsData].addf("N_LIB_PRIVATE TNimType $1;$n", [name])

proc genTypeInfoAux(m: BModule, typ, origType: PType, name: Rope;
                    info: TLineInfo) =
  var base: Rope
  if typ.len > 0 and typ.lastSon != nil:
    var x = typ.lastSon
    if typ.kind == tyObject: x = x.skipTypes(skipPtrs)
    if typ.kind == tyPtr and x.kind == tyObject and incompleteType(x):
      base = rope("0")
    else:
      base = genTypeInfoV1(m, x, info)
  else:
    base = rope("0")
  genTypeInfoAuxBase(m, typ, origType, name, base, info)

proc discriminatorTableName(m: BModule, objtype: PType, d: PSym): Rope =
  # bugfix: we need to search the type that contains the discriminator:
  var objtype = objtype.skipTypes(abstractPtrs)
  while lookupInRecord(objtype.n, d.name) == nil:
    objtype = objtype[0].skipTypes(abstractPtrs)
  if objtype.sym == nil:
    internalError(m.config, d.info, "anonymous obj with discriminator")
  result = "NimDT_$1_$2" % [rope($hashType(objtype, m.config)), rope(d.name.s.mangle)]

proc rope(arg: Int128): Rope = rope($arg)

proc discriminatorTableDecl(m: BModule, objtype: PType, d: PSym): Rope =
  discard cgsym(m, "TNimNode")
  var tmp = discriminatorTableName(m, objtype, d)
  result = "TNimNode* $1[$2];$n" % [tmp, rope(lengthOrd(m.config, d.typ)+1)]

proc genTNimNodeArray(m: BModule, name: Rope, size: Rope) =
  if m.hcrOn:
    m.s[cfsData].addf("static TNimNode** $1;$n", [name])
    m.hcrCreateTypeInfosProc.addf("\thcrRegisterGlobal($3, \"$1\", sizeof(TNimNode*) * $2, NULL, (void**)&$1);$n",
         [name, size, getModuleDllPath(m, m.module)])
  else:
    m.s[cfsTypeInit1].addf("static TNimNode* $1[$2];$n", [name, size])

proc genObjectFields(m: BModule, typ, origType: PType, n: PNode, expr: Rope;
                     info: TLineInfo) =
  case n.kind
  of nkRecList:
    if n.len == 1:
      genObjectFields(m, typ, origType, n[0], expr, info)
    elif n.len > 0:
      var tmp = getTempName(m) & "_" & $n.len
      genTNimNodeArray(m, tmp, rope(n.len))
      for i in 0..<n.len:
        var tmp2 = getNimNode(m)
        m.s[cfsTypeInit3].addf("$1[$2] = &$3;$n", [tmp, rope(i), tmp2])
        genObjectFields(m, typ, origType, n[i], tmp2, info)
      m.s[cfsTypeInit3].addf("$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n",
           [expr, rope(n.len), tmp])
    else:
      m.s[cfsTypeInit3].addf("$1.len = $2; $1.kind = 2;$n", [expr, rope(n.len)])
  of nkRecCase:
    assert(n[0].kind == nkSym)
    var field = n[0].sym
    var tmp = discriminatorTableName(m, typ, field)
    var L = lengthOrd(m.config, field.typ)
    assert L > 0
    if field.loc.r == nil: fillObjectFields(m, typ)
    if field.loc.t == nil:
      internalError(m.config, n.info, "genObjectFields")
    m.s[cfsTypeInit3].addf("$1.kind = 3;$n" &
        "$1.offset = offsetof($2, $3);$n" & "$1.typ = $4;$n" &
        "$1.name = $5;$n" & "$1.sons = &$6[0];$n" &
        "$1.len = $7;$n", [expr, getTypeDesc(m, origType, skVar), field.loc.r,
                           genTypeInfoV1(m, field.typ, info),
                           makeCString(field.name.s),
                           tmp, rope(L)])
    m.s[cfsData].addf("TNimNode* $1[$2];$n", [tmp, rope(L+1)])
    for i in 1..<n.len:
      var b = n[i]           # branch
      var tmp2 = getNimNode(m)
      genObjectFields(m, typ, origType, lastSon(b), tmp2, info)
      case b.kind
      of nkOfBranch:
        if b.len < 2:
          internalError(m.config, b.info, "genObjectFields; nkOfBranch broken")
        for j in 0..<b.len - 1:
          if b[j].kind == nkRange:
            var x = toInt(getOrdValue(b[j][0]))
            var y = toInt(getOrdValue(b[j][1]))
            while x <= y:
              m.s[cfsTypeInit3].addf("$1[$2] = &$3;$n", [tmp, rope(x), tmp2])
              inc(x)
          else:
            m.s[cfsTypeInit3].addf("$1[$2] = &$3;$n",
                 [tmp, rope(getOrdValue(b[j])), tmp2])
      of nkElse:
        m.s[cfsTypeInit3].addf("$1[$2] = &$3;$n",
             [tmp, rope(L), tmp2])
      else: internalError(m.config, n.info, "genObjectFields(nkRecCase)")
  of nkSym:
    var field = n.sym
    # Do not produce code for void types
    if isEmptyType(field.typ): return
    if field.bitsize == 0:
      if field.loc.r == nil: fillObjectFields(m, typ)
      if field.loc.t == nil:
        internalError(m.config, n.info, "genObjectFields")
      m.s[cfsTypeInit3].addf("$1.kind = 1;$n" &
          "$1.offset = offsetof($2, $3);$n" & "$1.typ = $4;$n" &
          "$1.name = $5;$n", [expr, getTypeDesc(m, origType, skVar),
          field.loc.r, genTypeInfoV1(m, field.typ, info), makeCString(field.name.s)])
  else: internalError(m.config, n.info, "genObjectFields")

proc genObjectInfo(m: BModule, typ, origType: PType, name: Rope; info: TLineInfo) =
  if typ.kind == tyObject:
    if incompleteType(typ):
      localError(m.config, info, "request for RTTI generation for incomplete object: " &
                        typeToString(typ))
    genTypeInfoAux(m, typ, origType, name, info)
  else:
    genTypeInfoAuxBase(m, typ, origType, name, rope("0"), info)
  var tmp = getNimNode(m)
  if not isImportedType(typ):
    genObjectFields(m, typ, origType, typ.n, tmp, info)
  m.s[cfsTypeInit3].addf("$1.node = &$2;$n", [tiNameForHcr(m, name), tmp])
  var t = typ[0]
  while t != nil:
    t = t.skipTypes(skipPtrs)
    t.flags.incl tfObjHasKids
    t = t[0]

proc genTupleInfo(m: BModule, typ, origType: PType, name: Rope; info: TLineInfo) =
  genTypeInfoAuxBase(m, typ, typ, name, rope("0"), info)
  var expr = getNimNode(m)
  if typ.len > 0:
    var tmp = getTempName(m) & "_" & $typ.len
    genTNimNodeArray(m, tmp, rope(typ.len))
    for i in 0..<typ.len:
      var a = typ[i]
      var tmp2 = getNimNode(m)
      m.s[cfsTypeInit3].addf("$1[$2] = &$3;$n", [tmp, rope(i), tmp2])
      m.s[cfsTypeInit3].addf("$1.kind = 1;$n" &
          "$1.offset = offsetof($2, Field$3);$n" &
          "$1.typ = $4;$n" &
          "$1.name = \"Field$3\";$n",
           [tmp2, getTypeDesc(m, origType, skVar), rope(i), genTypeInfoV1(m, a, info)])
    m.s[cfsTypeInit3].addf("$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n",
         [expr, rope(typ.len), tmp])
  else:
    m.s[cfsTypeInit3].addf("$1.len = $2; $1.kind = 2;$n",
         [expr, rope(typ.len)])
  m.s[cfsTypeInit3].addf("$1.node = &$2;$n", [tiNameForHcr(m, name), expr])

proc genEnumInfo(m: BModule, typ: PType, name: Rope; info: TLineInfo) =
  # Type information for enumerations is quite heavy, so we do some
  # optimizations here: The ``typ`` field is never set, as it is redundant
  # anyway. We generate a cstring array and a loop over it. Exceptional
  # positions will be reset after the loop.
  genTypeInfoAux(m, typ, typ, name, info)
  var nodePtrs = getTempName(m) & "_" & $typ.n.len
  genTNimNodeArray(m, nodePtrs, rope(typ.n.len))
  var enumNames, specialCases: Rope
  var firstNimNode = m.typeNodes
  var hasHoles = false
  for i in 0..<typ.n.len:
    assert(typ.n[i].kind == nkSym)
    var field = typ.n[i].sym
    var elemNode = getNimNode(m)
    if field.ast == nil:
      # no explicit string literal for the enum field, so use field.name:
      enumNames.add(makeCString(field.name.s))
    else:
      enumNames.add(makeCString(field.ast.strVal))
    if i < typ.n.len - 1: enumNames.add(", \L")
    if field.position != i or tfEnumHasHoles in typ.flags:
      specialCases.addf("$1.offset = $2;$n", [elemNode, rope(field.position)])
      hasHoles = true
  var enumArray = getTempName(m)
  var counter = getTempName(m)
  m.s[cfsTypeInit1].addf("NI $1;$n", [counter])
  m.s[cfsTypeInit1].addf("static char* NIM_CONST $1[$2] = {$n$3};$n",
       [enumArray, rope(typ.n.len), enumNames])
  m.s[cfsTypeInit3].addf("for ($1 = 0; $1 < $2; $1++) {$n" &
      "$3[$1+$4].kind = 1;$n" & "$3[$1+$4].offset = $1;$n" &
      "$3[$1+$4].name = $5[$1];$n" & "$6[$1] = &$3[$1+$4];$n" & "}$n", [counter,
      rope(typ.n.len), m.typeNodesName, rope(firstNimNode), enumArray, nodePtrs])
  m.s[cfsTypeInit3].add(specialCases)
  m.s[cfsTypeInit3].addf(
       "$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n$4.node = &$1;$n",
       [getNimNode(m), rope(typ.n.len), nodePtrs, tiNameForHcr(m, name)])
  if hasHoles:
    # 1 << 2 is {ntfEnumHole}
    m.s[cfsTypeInit3].addf("$1.flags = 1<<2;$n", [tiNameForHcr(m, name)])

proc genSetInfo(m: BModule, typ: PType, name: Rope; info: TLineInfo) =
  assert(typ[0] != nil)
  genTypeInfoAux(m, typ, typ, name, info)
  var tmp = getNimNode(m)
  m.s[cfsTypeInit3].addf("$1.len = $2; $1.kind = 0;$n" & "$3.node = &$1;$n",
       [tmp, rope(firstOrd(m.config, typ)), tiNameForHcr(m, name)])

proc genArrayInfo(m: BModule, typ: PType, name: Rope; info: TLineInfo) =
  genTypeInfoAuxBase(m, typ, typ, name, genTypeInfoV1(m, typ[1], info), info)

proc fakeClosureType(m: BModule; owner: PSym): PType =
  # we generate the same RTTI as for a tuple[pointer, ref tuple[]]
  result = newType(tyTuple, nextTypeId m.idgen, owner)
  result.rawAddSon(newType(tyPointer, nextTypeId m.idgen, owner))
  var r = newType(tyRef, nextTypeId m.idgen, owner)
  let obj = createObj(m.g.graph, m.idgen, owner, owner.info, final=false)
  r.rawAddSon(obj)
  result.rawAddSon(r)

include ccgtrav

proc genDeepCopyProc(m: BModule; s: PSym; result: Rope) =
  genProc(m, s)
  m.s[cfsTypeInit3].addf("$1.deepcopy =(void* (N_RAW_NIMCALL*)(void*))$2;$n",
     [result, s.loc.r])

proc declareNimType(m: BModule, name: string; str: Rope, module: int) =
  let nr = rope(name)
  if m.hcrOn:
    m.s[cfsData].addf("static $2* $1;$n", [str, nr])
    m.s[cfsTypeInit1].addf("\t$1 = ($3*)hcrGetGlobal($2, \"$1\");$n",
          [str, getModuleDllPath(m, module), nr])
  else:
    m.s[cfsData].addf("extern $2 $1;$n", [str, nr])

proc genTypeInfo2Name(m: BModule; t: PType): Rope =
  var res = "|"
  var it = t
  while it != nil:
    it = it.skipTypes(skipPtrs)
    if it.sym != nil and tfFromGeneric notin it.flags:
      var m = it.sym.owner
      while m != nil and m.kind != skModule: m = m.owner
      if m == nil or sfSystemModule in m.flags:
        # produce short names for system types:
        res.add it.sym.name.s
      else:
        var p = m.owner
        if p != nil and p.kind == skPackage:
          res.add p.name.s & "."
        res.add m.name.s & "."
        res.add it.sym.name.s
    else:
      res.add $hashType(it, m.config)
    res.add "|"
    it = it[0]
  result = makeCString(res)

proc isTrivialProc(g: ModuleGraph; s: PSym): bool {.inline.} = getBody(g, s).len == 0

proc genHook(m: BModule; t: PType; info: TLineInfo; op: TTypeAttachedOp): Rope =
  let theProc = getAttachedOp(m.g.graph, t, op)
  if theProc != nil and not isTrivialProc(m.g.graph, theProc):
    # the prototype of a destructor is ``=destroy(x: var T)`` and that of a
    # finalizer is: ``proc (x: ref T) {.nimcall.}``. We need to check the calling
    # convention at least:
    if theProc.typ == nil or theProc.typ.callConv != ccNimCall:
      localError(m.config, info,
        theProc.name.s & " needs to have the 'nimcall' calling convention")

    genProc(m, theProc)
    result = theProc.loc.r

    when false:
      if not canFormAcycle(m.g.graph, t) and op == attachedTrace:
        echo "ayclic but has this =trace ", t, " ", theProc.ast
  else:
    when false:
      if op == attachedTrace and m.config.selectedGC == gcOrc and
          containsGarbageCollectedRef(t):
        # unfortunately this check is wrong for an object type that only contains
        # .cursor fields like 'Node' inside 'cycleleak'.
        internalError(m.config, info, "no attached trace proc found")
    result = rope("NIM_NIL")

proc genTypeInfoV2Impl(m: BModule, t, origType: PType, name: Rope; info: TLineInfo) =
  var typeName: Rope
  if t.kind in {tyObject, tyDistinct}:
    if incompleteType(t):
      localError(m.config, info, "request for RTTI generation for incomplete object: " &
                 typeToString(t))
    typeName = genTypeInfo2Name(m, t)
  else:
    typeName = rope("NIM_NIL")

  discard cgsym(m, "TNimTypeV2")
  m.s[cfsData].addf("N_LIB_PRIVATE TNimTypeV2 $1;$n", [name])
  let destroyImpl = genHook(m, t, info, attachedDestructor)
  let traceImpl = genHook(m, t, info, attachedTrace)

  var flags = 0
  if not canFormAcycle(m.g.graph, t): flags = flags or 1

  addf(m.s[cfsTypeInit3], "$1.destructor = (void*)$2; $1.size = sizeof($3); $1.align = NIM_ALIGNOF($3); $1.name = $4;$n; $1.traceImpl = (void*)$5; $1.flags = $6;", [
    name, destroyImpl, getTypeDesc(m, t), typeName,
    traceImpl, rope(flags)])

  if t.kind == tyObject and t.len > 0 and t[0] != nil and optEnableDeepCopy in m.config.globalOptions:
    discard genTypeInfoV1(m, t, info)

proc genTypeInfoV2(m: BModule, t: PType; info: TLineInfo): Rope =
  let origType = t
  # distinct types can have their own destructors
  var t = skipTypes(origType, irrelevantForBackend + tyUserTypeClasses - {tyDistinct})

  let prefixTI = if m.hcrOn: "(" else: "(&"

  let sig = hashType(origType, m.config)
  result = m.typeInfoMarkerV2.getOrDefault(sig)
  if result != nil:
    return prefixTI.rope & result & ")".rope

  let marker = m.g.typeInfoMarkerV2.getOrDefault(sig)
  if marker.str != nil:
    discard cgsym(m, "TNimTypeV2")
    declareNimType(m, "TNimTypeV2", marker.str, marker.owner)
    # also store in local type section:
    m.typeInfoMarkerV2[sig] = marker.str
    return prefixTI.rope & marker.str & ")".rope

  result = "NTIv2$1_" % [rope($sig)]
  m.typeInfoMarkerV2[sig] = result

  let owner = t.skipTypes(typedescPtrs).itemId.module
  if owner != m.module.position and moduleOpenForCodegen(m.g.graph, FileIndex owner):
    # make sure the type info is created in the owner module
    discard genTypeInfoV2(m.g.modules[owner], origType, info)
    # reference the type info as extern here
    discard cgsym(m, "TNimTypeV2")
    declareNimType(m, "TNimTypeV2", result, owner)
    return prefixTI.rope & result & ")".rope

  m.g.typeInfoMarkerV2[sig] = (str: result, owner: owner)
  genTypeInfoV2Impl(m, t, origType, result, info)
  result = prefixTI.rope & result & ")".rope

proc openArrayToTuple(m: BModule; t: PType): PType =
  result = newType(tyTuple, nextTypeId m.idgen, t.owner)
  let p = newType(tyPtr, nextTypeId m.idgen, t.owner)
  let a = newType(tyUncheckedArray, nextTypeId m.idgen, t.owner)
  a.add t.lastSon
  p.add a
  result.add p
  result.add getSysType(m.g.graph, t.owner.info, tyInt)

proc typeToC(t: PType): string =
  ## Just for more readable names, the result doesn't have
  ## to be unique.
  let s = typeToString(t)
  result = newStringOfCap(s.len)
  for i in 0..<s.len:
    let c = s[i]
    case c
    of 'a'..'z':
      result.add c
    of 'A'..'Z':
      result.add toLowerAscii(c)
    of ' ':
      discard
    of ',':
      result.add '_'
    of '.':
      result.add 'O'
    of '[', '(', '{':
      result.add 'L'
    of ']', ')', '}':
      result.add 'T'
    else:
      # We mangle upper letters and digits too so that there cannot
      # be clashes with our special meanings
      result.addInt ord(c)

proc genTypeInfoV1(m: BModule, t: PType; info: TLineInfo): Rope =
  let origType = t
  var t = skipTypes(origType, irrelevantForBackend + tyUserTypeClasses)

  let prefixTI = if m.hcrOn: "(" else: "(&"

  let sig = hashType(origType, m.config)
  result = m.typeInfoMarker.getOrDefault(sig)
  if result != nil:
    return prefixTI.rope & result & ")".rope

  let marker = m.g.typeInfoMarker.getOrDefault(sig)
  if marker.str != nil:
    discard cgsym(m, "TNimType")
    discard cgsym(m, "TNimNode")
    declareNimType(m, "TNimType", marker.str, marker.owner)
    # also store in local type section:
    m.typeInfoMarker[sig] = marker.str
    return prefixTI.rope & marker.str & ")".rope

  result = "NTI$1$2_" % [rope(typeToC(t)), rope($sig)]
  m.typeInfoMarker[sig] = result

  let old = m.g.graph.emittedTypeInfo.getOrDefault($result)
  if old != FileIndex(0):
    discard cgsym(m, "TNimType")
    discard cgsym(m, "TNimNode")
    declareNimType(m, "TNimType", result, old.int)
    return prefixTI.rope & result & ")".rope

  var owner = t.skipTypes(typedescPtrs).itemId.module
  if owner != m.module.position and moduleOpenForCodegen(m.g.graph, FileIndex owner):
    # make sure the type info is created in the owner module
    discard genTypeInfoV1(m.g.modules[owner], origType, info)
    # reference the type info as extern here
    discard cgsym(m, "TNimType")
    discard cgsym(m, "TNimNode")
    declareNimType(m, "TNimType", result, owner)
    return prefixTI.rope & result & ")".rope
  else:
    owner = m.module.position.int32

  m.g.typeInfoMarker[sig] = (str: result, owner: owner)
  rememberEmittedTypeInfo(m.g.graph, FileIndex(owner), $result)

  case t.kind
  of tyEmpty, tyVoid: result = rope"0"
  of tyPointer, tyBool, tyChar, tyCstring, tyString, tyInt..tyUInt64, tyVar, tyLent:
    genTypeInfoAuxBase(m, t, t, result, rope"0", info)
  of tyStatic:
    if t.n != nil: result = genTypeInfoV1(m, lastSon t, info)
    else: internalError(m.config, "genTypeInfoV1(" & $t.kind & ')')
  of tyUserTypeClasses:
    internalAssert m.config, t.isResolvedUserTypeClass
    return genTypeInfoV1(m, t.lastSon, info)
  of tyProc:
    if t.callConv != ccClosure:
      genTypeInfoAuxBase(m, t, t, result, rope"0", info)
    else:
      let x = fakeClosureType(m, t.owner)
      genTupleInfo(m, x, x, result, info)
  of tySequence:
    genTypeInfoAux(m, t, t, result, info)
    if m.config.selectedGC in {gcMarkAndSweep, gcRefc, gcV2, gcGo}:
      let markerProc = genTraverseProc(m, origType, sig)
      m.s[cfsTypeInit3].addf("$1.marker = $2;$n", [tiNameForHcr(m, result), markerProc])
  of tyRef:
    genTypeInfoAux(m, t, t, result, info)
    if m.config.selectedGC in {gcMarkAndSweep, gcRefc, gcV2, gcGo}:
      let markerProc = genTraverseProc(m, origType, sig)
      m.s[cfsTypeInit3].addf("$1.marker = $2;$n", [tiNameForHcr(m, result), markerProc])
  of tyPtr, tyRange, tyUncheckedArray: genTypeInfoAux(m, t, t, result, info)
  of tyArray: genArrayInfo(m, t, result, info)
  of tySet: genSetInfo(m, t, result, info)
  of tyEnum: genEnumInfo(m, t, result, info)
  of tyObject:
    genObjectInfo(m, t, origType, result, info)
  of tyTuple:
    # if t.n != nil: genObjectInfo(m, t, result)
    # else:
    # BUGFIX: use consistently RTTI without proper field names; otherwise
    # results are not deterministic!
    genTupleInfo(m, t, origType, result, info)
  of tyOpenArray:
    let x = openArrayToTuple(m, t)
    genTupleInfo(m, x, origType, result, info)
  else: internalError(m.config, "genTypeInfoV1(" & $t.kind & ')')

  var op = getAttachedOp(m.g.graph, t, attachedDeepCopy)
  if op == nil:
    op = getAttachedOp(m.g.graph, origType, attachedDeepCopy)
  if op != nil:
    genDeepCopyProc(m, op, result)

  if optTinyRtti in m.config.globalOptions and t.kind == tyObject and sfImportc notin t.sym.flags:
    let v2info = genTypeInfoV2(m, origType, info)
    addf(m.s[cfsTypeInit3], "$1->typeInfoV1 = (void*)&$2; $2.typeInfoV2 = (void*)$1;$n", [
      v2info, result])

  result = prefixTI.rope & result & ")".rope

proc genTypeSection(m: BModule, n: PNode) =
  discard

proc genTypeInfo*(config: ConfigRef, m: BModule, t: PType; info: TLineInfo): Rope =
  if optTinyRtti in config.globalOptions:
    result = genTypeInfoV2(m, t, info)
  else:
    result = genTypeInfoV1(m, t, info)
