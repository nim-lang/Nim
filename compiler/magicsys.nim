#
#
#           The Nimrod Compiler
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Built-in types and compilerprocs are registered here.

import 
  ast, astalgo, nhashes, msgs, platform, nversion, times, idents, rodread

var SystemModule*: PSym

proc registerSysType*(t: PType)
  # magic symbols in the system module:
proc getSysType*(kind: TTypeKind): PType
proc getCompilerProc*(name: string): PSym
proc registerCompilerProc*(s: PSym)
proc InitSystem*(tab: var TSymTab)
proc FinishSystem*(tab: TStrTable)
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
  result = StrTableGet(systemModule.tab, getIdent(name))
  if result == nil: rawMessage(errSystemNeeds, name)
  if result.kind == skStub: loadStub(result)
  
proc sysTypeFromName(name: string): PType = 
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
    of tyFloat: result = sysTypeFromName("float")
    of tyFloat32: result = sysTypeFromName("float32")
    of tyFloat64: result = sysTypeFromName("float64")
    of tyBool: result = sysTypeFromName("bool")
    of tyChar: result = sysTypeFromName("char")
    of tyString: result = sysTypeFromName("string")
    of tyCstring: result = sysTypeFromName("cstring")
    of tyPointer: result = sysTypeFromName("pointer")
    of tyNil: result = newSysType(tyNil, ptrSize)
    else: InternalError("request for typekind: " & $kind)
    gSysTypes[kind] = result
  if result.kind != kind: 
    InternalError("wanted: " & $kind & " got: " & $result.kind)
  if result == nil: InternalError("type not found: " & $kind)
  
proc getCompilerProc(name: string): PSym = 
  var ident = getIdent(name, getNormalizedHash(name))
  result = StrTableGet(compilerprocs, ident)
  if result == nil: 
    result = StrTableGet(rodCompilerProcs, ident)
    if result != nil: 
      strTableAdd(compilerprocs, result)
      if result.kind == skStub: loadStub(result)
  
proc registerCompilerProc(s: PSym) = 
  strTableAdd(compilerprocs, s)

proc InitSystem(tab: var TSymTab) = nil
proc FinishSystem(tab: TStrTable) = nil
  
initStrTable(compilerprocs)

