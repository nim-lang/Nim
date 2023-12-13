#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std / [assertions, tables, sets]
import ".." / [ast, types, options, sighashes, modulegraphs]
import nirtypes

type
  TypesCon* = object
    processed: Table[ItemId, TypeId]
    processedByName: Table[string, TypeId]
    recursionCheck: HashSet[ItemId]
    conf: ConfigRef
    stringType: TypeId

proc initTypesCon*(conf: ConfigRef): TypesCon =
  TypesCon(conf: conf, stringType: TypeId(-1))

proc mangle(c: var TypesCon; t: PType): string =
  result = $sighashes.hashType(t, c.conf)

template cached(c: var TypesCon; t: PType; body: untyped) =
  result = c.processed.getOrDefault(t.itemId)
  if result.int == 0:
    body
    c.processed[t.itemId] = result

template cachedByName(c: var TypesCon; t: PType; body: untyped) =
  let key = mangle(c, t)
  result = c.processedByName.getOrDefault(key)
  if result.int == 0:
    body
    c.processedByName[key] = result

proc typeToIr*(c: var TypesCon; g: var TypeGraph; t: PType): TypeId

proc collectFieldTypes(c: var TypesCon; g: var TypeGraph; n: PNode; dest: var Table[ItemId, TypeId]) =
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      collectFieldTypes(c, g, n[i], dest)
  of nkRecCase:
    assert(n[0].kind == nkSym)
    collectFieldTypes(c, g, n[0], dest)
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        collectFieldTypes c, g, lastSon(n[i]), dest
      else: discard
  of nkSym:
    dest[n.sym.itemId] = typeToIr(c, g, n.sym.typ)
  else:
    assert false, "unknown node kind: " & $n.kind

proc objectToIr(c: var TypesCon; g: var TypeGraph; n: PNode; fieldTypes: Table[ItemId, TypeId]; unionId: var int) =
  case n.kind
  of nkRecList:
    for i in 0..<n.len:
      objectToIr(c, g, n[i], fieldTypes, unionId)
  of nkRecCase:
    assert(n[0].kind == nkSym)
    objectToIr(c, g, n[0], fieldTypes, unionId)
    let u = openType(g, UnionDecl)
    g.addName "u_" & $unionId
    inc unionId
    for i in 1..<n.len:
      case n[i].kind
      of nkOfBranch, nkElse:
        let subObj = openType(g, ObjectDecl)
        g.addName "uo_" & $unionId & "_" & $i
        objectToIr c, g, lastSon(n[i]), fieldTypes, unionId
        sealType(g, subObj)
      else: discard
    sealType(g, u)
  of nkSym:
    g.addField n.sym.name.s & "_" & $n.sym.position, fieldTypes[n.sym.itemId], n.sym.offset
  else:
    assert false, "unknown node kind: " & $n.kind

proc objectToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  if t.baseClass != nil:
    # ensure we emitted the base type:
    discard typeToIr(c, g, t.baseClass)

  var unionId = 0
  var fieldTypes = initTable[ItemId, TypeId]()
  collectFieldTypes c, g, t.n, fieldTypes
  let obj = openType(g, ObjectDecl)
  g.addName mangle(c, t)
  g.addSize c.conf.getSize(t)
  g.addAlign c.conf.getAlign(t)

  if t.baseClass != nil:
    g.addNominalType(ObjectTy, mangle(c, t.baseClass))
  else:
    g.addBuiltinType VoidId # object does not inherit
    if not lacksMTypeField(t):
      let f2 = g.openType FieldDecl
      let voidPtr = openType(g, APtrTy)
      g.addBuiltinType(VoidId)
      sealType(g, voidPtr)
      g.addOffset 0 # type field is always at offset 0
      g.addName "m_type"
      sealType(g, f2) # FieldDecl

  objectToIr c, g, t.n, fieldTypes, unionId
  result = finishType(g, obj)

proc objectHeaderToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  result = g.nominalType(ObjectTy, mangle(c, t))

proc tupleToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  var fieldTypes = newSeq[TypeId](t.len)
  for i in 0..<t.len:
    fieldTypes[i] = typeToIr(c, g, t[i])
  let obj = openType(g, ObjectDecl)
  g.addName mangle(c, t)
  g.addSize c.conf.getSize(t)
  g.addAlign c.conf.getAlign(t)

  var accum = OffsetAccum(maxAlign: 1)
  for i in 0..<t.len:
    let child = t[i]
    g.addField "f_" & $i, fieldTypes[i], accum.offset

    computeSizeAlign(c.conf, child)
    accum.align(child.align)
    accum.inc(int32(child.size))
  result = finishType(g, obj)

proc procToIr(c: var TypesCon; g: var TypeGraph; t: PType; addEnv = false): TypeId =
  var fieldTypes = newSeq[TypeId](0)
  for i in 0..<t.len:
    if t[i] == nil or not isCompileTimeOnly(t[i]):
      fieldTypes.add typeToIr(c, g, t[i])
  let obj = openType(g, ProcTy)

  case t.callConv
  of ccNimCall, ccFastCall, ccClosure: g.addAnnotation "__fastcall"
  of ccStdCall: g.addAnnotation "__stdcall"
  of ccCDecl: g.addAnnotation "__cdecl"
  of ccSafeCall: g.addAnnotation "__safecall"
  of ccSysCall: g.addAnnotation "__syscall"
  of ccInline: g.addAnnotation "__inline"
  of ccNoInline: g.addAnnotation "__noinline"
  of ccThisCall: g.addAnnotation "__thiscall"
  of ccNoConvention: g.addAnnotation ""

  for i in 0..<fieldTypes.len:
    g.addType fieldTypes[i]

  if addEnv:
    let a = openType(g, APtrTy)
    g.addBuiltinType(VoidId)
    sealType(g, a)

  if tfVarargs in t.flags:
    g.addVarargs()
  result = finishType(g, obj)

proc nativeInt(c: TypesCon): TypeId =
  case c.conf.target.intSize
  of 2: result = Int16Id
  of 4: result = Int32Id
  else: result = Int64Id

proc openArrayPayloadType*(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  let e = elementType(t)
  let elementType = typeToIr(c, g, e)
  let arr = g.openType AArrayPtrTy
  g.addType elementType
  result = finishType(g, arr) # LastArrayTy

proc openArrayToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  # object (a: ArrayPtr[T], len: int)
  let e = elementType(t)
  let mangledBase = mangle(c, e)
  let typeName = "NimOpenArray" & mangledBase

  let elementType = typeToIr(c, g, e)
  #assert elementType.int >= 0, typeToString(t)

  let p = openType(g, ObjectDecl)
  g.addName typeName
  g.addSize c.conf.target.ptrSize*2
  g.addAlign c.conf.target.ptrSize

  let f = g.openType FieldDecl
  let arr = g.openType AArrayPtrTy
  g.addType elementType
  sealType(g, arr) # LastArrayTy
  g.addOffset 0
  g.addName "data"
  sealType(g, f) # FieldDecl

  g.addField "len", c.nativeInt, c.conf.target.ptrSize

  result = finishType(g, p) # ObjectDecl

proc strPayloadType(c: var TypesCon; g: var TypeGraph): (string, TypeId) =
  result = ("NimStrPayload", TypeId(-1))
  let p = openType(g, ObjectDecl)
  g.addName result[0]
  g.addSize c.conf.target.ptrSize*2
  g.addAlign c.conf.target.ptrSize

  g.addField "cap", c.nativeInt, 0

  let f = g.openType FieldDecl
  let arr = g.openType LastArrayTy
  g.addBuiltinType Char8Id
  result[1] = finishType(g, arr) # LastArrayTy
  g.addOffset c.conf.target.ptrSize # comes after the len field
  g.addName "data"
  sealType(g, f) # FieldDecl

  sealType(g, p)

proc strPayloadPtrType*(c: var TypesCon; g: var TypeGraph): (TypeId, TypeId) =
  let (mangled, arrayType) = strPayloadType(c, g)
  let ffp = g.openType APtrTy
  g.addNominalType ObjectTy, mangled
  result = (finishType(g, ffp), arrayType) # APtrTy

proc stringToIr(c: var TypesCon; g: var TypeGraph): TypeId =
  #[

    NimStrPayload = object
      cap: int
      data: UncheckedArray[char]

    NimStringV2 = object
      len: int
      p: ptr NimStrPayload

  ]#
  let payload = strPayloadType(c, g)

  let str = openType(g, ObjectDecl)
  g.addName "NimStringV2"
  g.addSize c.conf.target.ptrSize*2
  g.addAlign c.conf.target.ptrSize

  g.addField "len", c.nativeInt, 0

  let fp = g.openType FieldDecl
  let ffp = g.openType APtrTy
  g.addNominalType ObjectTy, "NimStrPayload"
  sealType(g, ffp) # APtrTy
  g.addOffset c.conf.target.ptrSize # comes after 'len' field
  g.addName "p"
  sealType(g, fp) # FieldDecl

  result = finishType(g, str) # ObjectDecl

proc seqPayloadType(c: var TypesCon; g: var TypeGraph; t: PType): (string, TypeId) =
  #[
    NimSeqPayload[T] = object
      cap: int
      data: UncheckedArray[T]
  ]#
  let e = elementType(t)
  result = (mangle(c, e), TypeId(-1))
  let payloadName = "NimSeqPayload" & result[0]

  let elementType = typeToIr(c, g, e)

  let p = openType(g, ObjectDecl)
  g.addName payloadName
  g.addSize c.conf.target.intSize
  g.addAlign c.conf.target.intSize

  g.addField "cap", c.nativeInt, 0

  let f = g.openType FieldDecl
  let arr = g.openType LastArrayTy
  g.addType elementType
  # DO NOT USE `finishType` here as it is an inner type. This is subtle and we
  # probably need an even better API here.
  sealType(g, arr)
  result[1] = TypeId(arr)

  g.addOffset c.conf.target.ptrSize
  g.addName "data"
  sealType(g, f) # FieldDecl

  sealType(g, p)

proc seqPayloadPtrType*(c: var TypesCon; g: var TypeGraph; t: PType): (TypeId, TypeId) =
  let (mangledBase, arrayType) = seqPayloadType(c, g, t)
  let ffp = g.openType APtrTy
  g.addNominalType ObjectTy, "NimSeqPayload" & mangledBase
  result = (finishType(g, ffp), arrayType) # APtrTy

proc seqToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  #[
    NimSeqV2*[T] = object
      len: int
      p: ptr NimSeqPayload[T]
  ]#
  let (mangledBase, _) = seqPayloadType(c, g, t)

  let sq = openType(g, ObjectDecl)
  g.addName "NimSeqV2" & mangledBase
  g.addSize c.conf.getSize(t)
  g.addAlign c.conf.getAlign(t)

  g.addField "len", c.nativeInt, 0

  let fp = g.openType FieldDecl
  let ffp = g.openType APtrTy
  g.addNominalType ObjectTy, "NimSeqPayload" & mangledBase
  sealType(g, ffp) # APtrTy
  g.addOffset c.conf.target.ptrSize
  g.addName "p"
  sealType(g, fp) # FieldDecl

  result = finishType(g, sq) # ObjectDecl


proc closureToIr(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  # struct {fn(args, void* env), env}
  # typedef struct {$n" &
  #        "N_NIMCALL_PTR($2, ClP_0) $3;$n" &
  #        "void* ClE_0;$n} $1;$n"
  let mangledBase = mangle(c, t)
  let typeName = "NimClosure" & mangledBase

  let procType = procToIr(c, g, t, addEnv=true)

  let p = openType(g, ObjectDecl)
  g.addName typeName
  g.addSize c.conf.getSize(t)
  g.addAlign c.conf.getAlign(t)

  let f = g.openType FieldDecl
  g.addType procType
  g.addOffset 0
  g.addName "ClP_0"
  sealType(g, f) # FieldDecl

  let f2 = g.openType FieldDecl
  let voidPtr = openType(g, APtrTy)
  g.addBuiltinType(VoidId)
  sealType(g, voidPtr)

  g.addOffset c.conf.target.ptrSize
  g.addName "ClE_0"
  sealType(g, f2) # FieldDecl

  result = finishType(g, p) # ObjectDecl

proc bitsetBasetype*(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  let s = int(getSize(c.conf, t))
  case s
  of 1: result = UInt8Id
  of 2: result = UInt16Id
  of 4: result = UInt32Id
  of 8: result = UInt64Id
  else: result = UInt8Id

proc typeToIr*(c: var TypesCon; g: var TypeGraph; t: PType): TypeId =
  if t == nil: return VoidId
  case t.kind
  of tyInt:
    case int(getSize(c.conf, t))
    of 2: result = Int16Id
    of 4: result = Int32Id
    else: result = Int64Id
  of tyInt8: result = Int8Id
  of tyInt16: result = Int16Id
  of tyInt32: result = Int32Id
  of tyInt64: result = Int64Id
  of tyFloat:
    case int(getSize(c.conf, t))
    of 4: result = Float32Id
    else: result = Float64Id
  of tyFloat32: result = Float32Id
  of tyFloat64: result = Float64Id
  of tyFloat128: result = getFloat128Type(g)
  of tyUInt:
    case int(getSize(c.conf, t))
    of 2: result = UInt16Id
    of 4: result = UInt32Id
    else: result = UInt64Id
  of tyUInt8: result = UInt8Id
  of tyUInt16: result = UInt16Id
  of tyUInt32: result = UInt32Id
  of tyUInt64: result = UInt64Id
  of tyBool: result = Bool8Id
  of tyChar: result = Char8Id
  of tyVoid: result = VoidId
  of tySink, tyGenericInst, tyDistinct, tyAlias, tyOwned, tyRange:
    result = typeToIr(c, g, t.skipModifier)
  of tyEnum:
    if firstOrd(c.conf, t) < 0:
      result = Int32Id
    else:
      case int(getSize(c.conf, t))
      of 1: result = UInt8Id
      of 2: result = UInt16Id
      of 4: result = Int32Id
      of 8: result = Int64Id
      else: result = Int32Id
  of tyOrdinal, tyGenericBody, tyGenericParam, tyInferred, tyStatic:
    if t.len > 0:
      result = typeToIr(c, g, t.skipModifier)
    else:
      result = TypeId(-1)
  of tyFromExpr:
    if t.n != nil and t.n.typ != nil:
      result = typeToIr(c, g, t.n.typ)
    else:
      result = TypeId(-1)
  of tyArray:
    cached(c, t):
      var n = toInt64(lengthOrd(c.conf, t))
      if n <= 0: n = 1   # make an array of at least one element
      let elemType = typeToIr(c, g, t.elementType)
      let a = openType(g, ArrayTy)
      g.addType(elemType)
      g.addArrayLen n
      g.addName mangle(c, t)
      result = finishType(g, a)
  of tyPtr, tyRef:
    cached(c, t):
      let e = t.elementType
      if e.kind == tyUncheckedArray:
        let elemType = typeToIr(c, g, e.elementType)
        let a = openType(g, AArrayPtrTy)
        g.addType(elemType)
        result = finishType(g, a)
      else:
        let elemType = typeToIr(c, g, t.elementType)
        let a = openType(g, APtrTy)
        g.addType(elemType)
        result = finishType(g, a)
  of tyVar, tyLent:
    cached(c, t):
      let e = t.elementType
      if e.skipTypes(abstractInst).kind in {tyOpenArray, tyVarargs}:
        # skip the modifier, `var openArray` is a (ptr, len) pair too:
        result = typeToIr(c, g, e)
      else:
        let elemType = typeToIr(c, g, e)
        let a = openType(g, APtrTy)
        g.addType(elemType)
        result = finishType(g, a)
  of tySet:
    let s = int(getSize(c.conf, t))
    case s
    of 1: result = UInt8Id
    of 2: result = UInt16Id
    of 4: result = UInt32Id
    of 8: result = UInt64Id
    else:
      # array[U8, s]
      cached(c, t):
        let a = openType(g, ArrayTy)
        g.addType(UInt8Id)
        g.addArrayLen s
        g.addName mangle(c, t)
        result = finishType(g, a)
  of tyPointer, tyNil:
    # tyNil can happen for code like: `const CRAP = nil` which we have in posix.nim
    let a = openType(g, APtrTy)
    g.addBuiltinType(VoidId)
    result = finishType(g, a)
  of tyObject:
    # Objects are special as they can be recursive in Nim. This is easily solvable.
    # We check if we are already "processing" t. If so, we produce `ObjectTy`
    # instead of `ObjectDecl`.
    cached(c, t):
      if not c.recursionCheck.containsOrIncl(t.itemId):
        result = objectToIr(c, g, t)
      else:
        result = objectHeaderToIr(c, g, t)
  of tyTuple:
    cachedByName(c, t):
      result = tupleToIr(c, g, t)
  of tyProc:
    cached(c, t):
      if t.callConv == ccClosure:
        result = closureToIr(c, g, t)
      else:
        result = procToIr(c, g, t)
  of tyVarargs, tyOpenArray:
    cached(c, t):
      result = openArrayToIr(c, g, t)
  of tyString:
    if c.stringType.int < 0:
      result = stringToIr(c, g)
      c.stringType = result
    else:
      result = c.stringType
  of tySequence:
    cachedByName(c, t):
      result = seqToIr(c, g, t)
  of tyCstring:
    cached(c, t):
      let a = openType(g, AArrayPtrTy)
      g.addBuiltinType Char8Id
      result = finishType(g, a)
  of tyUncheckedArray:
    # We already handled the `ptr UncheckedArray` in a special way.
    cached(c, t):
      let elemType = typeToIr(c, g, t.elementType)
      let a = openType(g, LastArrayTy)
      g.addType(elemType)
      result = finishType(g, a)
  of tyUntyped, tyTyped:
    # this avoids a special case for system.echo which is not a generic but
    # uses `varargs[typed]`:
    result = VoidId
  of tyNone, tyEmpty, tyTypeDesc,
     tyGenericInvocation, tyProxy, tyBuiltInTypeClass,
     tyUserTypeClass, tyUserTypeClassInst, tyCompositeTypeClass,
     tyAnd, tyOr, tyNot, tyAnything, tyConcept, tyIterable, tyForward:
    result = TypeId(-1)
