#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Built-in types and compilerprocs are registered here.

import 
  ast, astalgo, hashes, msgs, platform, nversion, times, idents, rodread

var systemModule*: PSym

proc registerSysType*(t: PType)
  # magic symbols in the system module:
proc getSysType*(kind: TTypeKind): PType
proc getCompilerProc*(name: string): PSym
proc registerCompilerProc*(s: PSym)
proc finishSystem*(tab: TStrTable)
proc getSysSym*(name: string): PSym
# implementation

var
  gSysTypes: array[TTypeKind, PType]
  compilerprocs: TStrTable

proc registerSysType(t: PType) = 
  if gSysTypes[t.kind] == nil: gSysTypes[t.kind] = t
  
proc newSysType(kind: TTypeKind, size: int): PType = 
  result = newType(kind, systemModule)
  result.size = size
  result.align = size

proc getSysSym(name: string): PSym = 
  result = strTableGet(systemModule.tab, getIdent(name))
  if result == nil: 
    rawMessage(errSystemNeeds, name)
    result = newSym(skError, getIdent(name), systemModule, systemModule.info)
    result.typ = newType(tyError, systemModule)
  if result.kind == skStub: loadStub(result)
  
proc getSysMagic*(name: string, m: TMagic): PSym =
  var ti: TIdentIter
  let id = getIdent(name)
  result = initIdentIter(ti, systemModule.tab, id)
  while result != nil:
    if result.kind == skStub: loadStub(result)
    if result.magic == m: return result
    result = nextIdentIter(ti, systemModule.tab)
  rawMessage(errSystemNeeds, name)
  result = newSym(skError, id, systemModule, systemModule.info)
  result.typ = newType(tyError, systemModule)
  
proc sysTypeFromName*(name: string): PType = 
  result = getSysSym(name).typ

proc getSysType(kind: TTypeKind): PType = 
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

proc getCompilerProc(name: string): PSym = 
  var ident = getIdent(name, hashIgnoreStyle(name))
  result = strTableGet(compilerprocs, ident)
  if result == nil: 
    result = strTableGet(rodCompilerprocs, ident)
    if result != nil: 
      strTableAdd(compilerprocs, result)
      if result.kind == skStub: loadStub(result)
  
proc registerCompilerProc(s: PSym) = 
  strTableAdd(compilerprocs, s)

proc finishSystem(tab: TStrTable) = discard

initStrTable(compilerprocs)
