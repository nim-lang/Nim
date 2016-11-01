#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Built-in types and compilerprocs are registered here.

import
  ast, astalgo, hashes, msgs, platform, nversion, times, idents, rodread

var systemModule*: PSym

var
  gSysTypes: array[TTypeKind, PType]
  compilerprocs: TStrTable
  exposed: TStrTable

proc nilOrSysInt*: PType = gSysTypes[tyInt]

proc registerSysType*(t: PType) =
  if gSysTypes[t.kind] == nil: gSysTypes[t.kind] = t

proc newSysType(kind: TTypeKind, size: int): PType =
  result = newType(kind, systemModule)
  result.size = size
  result.align = size.int16

proc getSysSym*(name: string): PSym =
  result = strTableGet(systemModule.tab, getIdent(name))
  if result == nil:
    rawMessage(errSystemNeeds, name)
    result = newSym(skError, getIdent(name), systemModule, systemModule.info)
    result.typ = newType(tyError, systemModule)
  if result.kind == skStub: loadStub(result)
  if result.kind == skAlias: result = result.owner

proc createMagic*(name: string, m: TMagic): PSym =
  result = newSym(skProc, getIdent(name), nil, unknownLineInfo())
  result.magic = m

let
  opNot* = createMagic("not", mNot)
  opContains* = createMagic("contains", mInSet)

proc getSysMagic*(name: string, m: TMagic): PSym =
  var ti: TIdentIter
  let id = getIdent(name)
  var r = initIdentIter(ti, systemModule.tab, id)
  while r != nil:
    if r.kind == skStub: loadStub(r)
    if r.magic == m:
      # prefer the tyInt variant:
      if r.typ.sons[0] != nil and r.typ.sons[0].kind == tyInt: return r
      result = r
    r = nextIdentIter(ti, systemModule.tab)
  if result != nil: return result
  rawMessage(errSystemNeeds, name)
  result = newSym(skError, id, systemModule, systemModule.info)
  result.typ = newType(tyError, systemModule)

proc sysTypeFromName*(name: string): PType =
  result = getSysSym(name).typ

proc getSysType*(kind: TTypeKind): PType =
  result = gSysTypes[kind]
  if result == nil:
    case kind
    of tyInt: result = sysTypeFromName("int")
    of tyInt8: result = sysTypeFromName("int8")
    of tyInt16: result = sysTypeFromName("int16")
    of tyInt32: result = sysTypeFromName("int32")
    of tyInt64: result = sysTypeFromName("int64")
    of tyUInt: result = sysTypeFromName("uint")
    of tyUInt8: result = sysTypeFromName("uint8")
    of tyUInt16: result = sysTypeFromName("uint16")
    of tyUInt32: result = sysTypeFromName("uint32")
    of tyUInt64: result = sysTypeFromName("uint64")
    of tyFloat: result = sysTypeFromName("float")
    of tyFloat32: result = sysTypeFromName("float32")
    of tyFloat64: return sysTypeFromName("float64")
    of tyFloat128: result = sysTypeFromName("float128")
    of tyBool: result = sysTypeFromName("bool")
    of tyChar: result = sysTypeFromName("char")
    of tyString: result = sysTypeFromName("string")
    of tyCString: result = sysTypeFromName("cstring")
    of tyPointer: result = sysTypeFromName("pointer")
    of tyNil: result = newSysType(tyNil, ptrSize)
    else: internalError("request for typekind: " & $kind)
    gSysTypes[kind] = result
  if result.kind != kind:
    internalError("wanted: " & $kind & " got: " & $result.kind)
  if result == nil: internalError("type not found: " & $kind)

var
  intTypeCache: array[-5..64, PType]

proc resetSysTypes* =
  systemModule = nil
  initStrTable(compilerprocs)
  initStrTable(exposed)
  for i in low(gSysTypes)..high(gSysTypes):
    gSysTypes[i] = nil

  for i in low(intTypeCache)..high(intTypeCache):
    intTypeCache[i] = nil

proc getIntLitType*(literal: PNode): PType =
  # we cache some common integer literal types for performance:
  let value = literal.intVal
  if value >= low(intTypeCache) and value <= high(intTypeCache):
    result = intTypeCache[value.int]
    if result == nil:
      let ti = getSysType(tyInt)
      result = copyType(ti, ti.owner, false)
      result.n = literal
      intTypeCache[value.int] = result
  else:
    let ti = getSysType(tyInt)
    result = copyType(ti, ti.owner, false)
    result.n = literal

proc getFloatLitType*(literal: PNode): PType =
  # for now we do not cache these:
  result = newSysType(tyFloat, size=8)
  result.n = literal

proc skipIntLit*(t: PType): PType {.inline.} =
  if t.n != nil:
    if t.kind in {tyInt, tyFloat}:
      return getSysType(t.kind)
  result = t

proc addSonSkipIntLit*(father, son: PType) =
  if isNil(father.sons): father.sons = @[]
  let s = son.skipIntLit
  add(father.sons, s)
  propagateToOwner(father, s)

proc setIntLitType*(result: PNode) =
  let i = result.intVal
  case platform.intSize
  of 8: result.typ = getIntLitType(result)
  of 4:
    if i >= low(int32) and i <= high(int32):
      result.typ = getIntLitType(result)
    else:
      result.typ = getSysType(tyInt64)
  of 2:
    if i >= low(int16) and i <= high(int16):
      result.typ = getIntLitType(result)
    elif i >= low(int32) and i <= high(int32):
      result.typ = getSysType(tyInt32)
    else:
      result.typ = getSysType(tyInt64)
  of 1:
    # 8 bit CPUs are insane ...
    if i >= low(int8) and i <= high(int8):
      result.typ = getIntLitType(result)
    elif i >= low(int16) and i <= high(int16):
      result.typ = getSysType(tyInt16)
    elif i >= low(int32) and i <= high(int32):
      result.typ = getSysType(tyInt32)
    else:
      result.typ = getSysType(tyInt64)
  else: internalError(result.info, "invalid int size")

proc getCompilerProc*(name: string): PSym =
  let ident = getIdent(name)
  result = strTableGet(compilerprocs, ident)
  if result == nil:
    result = strTableGet(rodCompilerprocs, ident)
    if result != nil:
      strTableAdd(compilerprocs, result)
      if result.kind == skStub: loadStub(result)
      if result.kind == skAlias: result = result.owner

proc registerCompilerProc*(s: PSym) =
  strTableAdd(compilerprocs, s)

proc registerNimScriptSymbol*(s: PSym) =
  # Nimscript symbols must be al unique:
  let conflict = strTableGet(exposed, s.name)
  if conflict == nil:
    strTableAdd(exposed, s)
  else:
    localError(s.info, "symbol conflicts with other .exportNims symbol at: " &
      $conflict.info)

proc getNimScriptSymbol*(name: string): PSym =
  strTableGet(exposed, getIdent(name))

proc resetNimScriptSymbols*() = initStrTable(exposed)

initStrTable(compilerprocs)
initStrTable(exposed)
