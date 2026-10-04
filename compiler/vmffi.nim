#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The FFI of the VM (`--experimental:compiletimeFFI`). The VM keeps its
## values in host memory that is laid out like C lays it out, so a foreign
## call only has to point libffi at the argument slots: no packing or
## unpacking of values is required.

import ast, types, options, msgs, lineinfos, vmlayout, vmmem
from std/os import getAppFilename
import libffi/libffi

import std/[tables, dynlib]

when defined(windows):
  const libcDll = "msvcrt.dll"
elif defined(linux):
  const libcDll = "libc.so(.6|.5|)"
elif defined(openbsd):
  const libcDll = "/usr/lib/libc.so(.95.1|)"
elif defined(bsd):
  const libcDll = "/lib/libc.so.7"
elif defined(osx):
  const libcDll = "/usr/lib/libSystem.dylib"
else:
  {.error: "`libcDll` not implemented on this platform".}

when defined(windows):
  const ffiDll = "libffi-(8|7).dll"
elif defined(osx):
  const ffiDll = "libffi.dylib"
else:
  const ffiDll = "libffi.so(.8|.7|)"

proc prepCifVar(cif: var TCif; abi: TABI; nfixedargs, ntotalargs: cuint;
                rtype: ptr Type; atypes: ParamList): Status {.cdecl,
  importc: "ffi_prep_cif_var", dynlib: ffiDll.}

type
  FfiArg* = object
    kind*: MemKind
    isString*: bool  ## a Nim string passed to a C vararg: pass its data
    offset*: int     ## byte offset of the argument in the call area

  FfiSite* = object
    ## a call of an imported proc
    fn*: pointer
    abi: TABI
    args*: seq[FfiArg]
    fixedArgs*: int  ## < args.len for a call of a C varargs proc
    ret*: MemKind    ## mkBlock for `void`
    hasResult*: bool

var
  gDllCache = initTable[string, LibHandle]()

when defined(windows):
  var gExeHandle = loadLib(getAppFilename())
else:
  var gExeHandle = loadLib()

proc getDll(conf: ConfigRef; dll: string; info: TLineInfo): LibHandle =
  result = gDllCache.getOrDefault(dll)
  if result != nil: return
  var libs: seq[string] = @[]
  libCandidates(dll, libs)
  for c in libs:
    result = loadLib(c)
    if not result.isNil: break
  if result.isNil:
    globalError(conf, info, "cannot load: " & dll)
  gDllCache[dll] = result

when defined(musl):
  var nativeErrno {.importc: "errno", header: "<errno.h>".}: cint

proc importcSymbol*(conf: ConfigRef; sym: PSym): pointer =
  ## the host address of the imported proc or variable `sym`.
  let name = sym.cname
  var libPathMsg = ""
  let lib = sym.annex
  if lib != nil and lib.path.kind notin {nkStrLit..nkTripleStrLit}:
    globalError(conf, sym.info, "dynlib needs to be a string lit")
  result = nil
  if (lib.isNil or lib.kind == libHeader) and not gExeHandle.isNil:
    libPathMsg = "current exe: " & getAppFilename() & " nor libc: " & libcDll
    # first try this exe itself:
    result = gExeHandle.symAddr(name.cstring)
    # then try libc:
    if result.isNil:
      result = getDll(conf, libcDll, sym.info).symAddr(name.cstring)
  elif not lib.isNil:
    let dll = if lib.kind == libHeader: libcDll else: lib.path.strVal
    libPathMsg = dll
    result = getDll(conf, dll, sym.info).symAddr(name.cstring)
  when defined(musl):
    if result.isNil and name == "errno" and sym.kind == skVar and
        (lib.isNil or lib.kind == libHeader):
      result = addr nativeErrno
  if result.isNil:
    globalError(conf, sym.info, "cannot import symbol: " & name & " from " & libPathMsg)

when defined(arm64) and not defined(windows):
  # the wrapper's `TABI` is that of x86-64: `UNIX64` is `FFI_WIN64` on
  # aarch64, which passes C varargs differently. `FFI_SYSV` is 1 there.
  const hostAbi = SYSV
else:
  const hostAbi = DEFAULT_ABI

proc mapCallConv(conf: ConfigRef; cc: TCallingConvention; info: TLineInfo): TABI =
  case cc
  of ccNimCall, ccCDecl: result = hostAbi
  of ccStdCall: result = when defined(windows) and defined(x86): STDCALL else: hostAbi
  else:
    result = default(TABI)
    globalError(conf, info, "cannot map calling convention to FFI")

proc ffiArgKind*(conf: ConfigRef; t: PType; info: TLineInfo): FfiArg =
  ## how a value of type `t` is passed to a foreign proc.
  let t = t.skipTypes(abstractInst+{tySink})
  case t.kind
  of tyString:
    result = FfiArg(kind: mkPtr, isString: true)
  of tyProc:
    # a VM proc address is not callable by foreign code
    result = FfiArg(kind: mkBlock)
    globalError(conf, info, "cannot pass a proc to a foreign proc at compile time")
  else:
    result = FfiArg(kind: memKind(conf, t))
    if result.kind in {mkBlock, mkNode}:
      globalError(conf, info, "cannot map FFI type: " & typeToString(t))

proc initFfiSite*(conf: ConfigRef; sym: PSym; args: sink seq[FfiArg];
                  fixedArgs: int; info: TLineInfo): FfiSite =
  let ret = sym.typ.returnType
  let hasResult = ret != nil and not isEmptyType(ret)
  result = FfiSite(fn: importcSymbol(conf, sym),
                   abi: mapCallConv(conf, sym.typ.callConv, info),
                   args: args, fixedArgs: fixedArgs,
                   ret: if hasResult: ffiArgKind(conf, ret, info).kind else: mkBlock,
                   hasResult: hasResult)

proc ffiType(k: MemKind; promote: bool): ptr libffi.Type =
  ## `promote`: the C default argument promotions of variadic arguments.
  case k
  of mkI8: result = if promote: addr type_sint32 else: addr type_sint8
  of mkU8: result = if promote: addr type_sint32 else: addr type_uint8
  of mkI16: result = if promote: addr type_sint32 else: addr type_sint16
  of mkU16: result = if promote: addr type_sint32 else: addr type_uint16
  of mkI32: result = addr type_sint32
  of mkU32: result = addr type_uint32
  of mkI64: result = addr type_sint64
  of mkU64: result = addr type_uint64
  of mkF32: result = if promote: addr type_double else: addr type_float
  of mkF64: result = addr type_double
  of mkPtr: result = addr type_pointer
  of mkBlock, mkNode: result = addr type_void

proc callForeign*(conf: ConfigRef; site: FfiSite; args, res: Address;
                  info: TLineInfo) =
  ## calls `site.fn`; the arguments are in the VM's slots at `args`, the
  ## result is written to the slot at `res`. Registers hold scalars widened
  ## to 64 bits, so on a little endian host the slot itself can be passed for
  ## every integral type.
  # libffi's `ffi_cif` can have more fields than the wrapper's `TCif`
  # (`FFI_EXTRA_CIF_FIELDS`, like `aarch64_nfixedargs` for varargs):
  var cifBuf = default(tuple[cif: TCif, extra: array[4, uint64]])
  template cif: untyped = cifBuf.cif
  var sig = default(ParamList)
  var cargs = default(ArgList)
  # floats are widened to `float64` in registers and strings need their
  # data pointer: such arguments are passed via this scratch space.
  var scratch = newSeq[uint64](site.args.len)
  var empty = 0'u8
  for i in 0..<site.args.len:
    let a = site.args[i]
    let promote = i >= site.fixedArgs
    sig[i] = ffiType(a.kind, promote)
    let slot = args +! a.offset
    if a.isString:
      let p = ld[Address](slot +! StrPayloadOffset)
      scratch[i] = if p == 0: uint64(toAddr(addr empty))
                   else: uint64(p +! PayloadDataOffset)
      cargs[i] = addr scratch[i]
    elif a.kind == mkF32 and not promote:
      cast[ptr float32](addr scratch[i])[] = float32(ld[float64](slot))
      cargs[i] = addr scratch[i]
    else:
      cargs[i] = toPtr(slot)
  let rtype = if site.hasResult: ffiType(site.ret, false) else: addr type_void
  let status =
    if site.fixedArgs < site.args.len:
      prepCifVar(cif, site.abi, cuint(site.fixedArgs), cuint(site.args.len), rtype, sig)
    else:
      prep_cif(cif, site.abi, cuint(site.args.len), rtype, sig)
  if status != OK:
    globalError(conf, info, "error in FFI call")
  # libffi widens integral results to at least `ffi_arg`:
  var ret: uint64 = 0
  libffi.call(cif, site.fn, addr ret, cargs)
  if site.hasResult:
    let v =
      case site.ret
      of mkI8: int64(cast[int8](ret))
      of mkU8: int64(cast[uint8](ret))
      of mkI16: int64(cast[int16](ret))
      of mkU16: int64(cast[uint16](ret))
      of mkI32: int64(cast[int32](ret))
      of mkU32: int64(cast[uint32](ret))
      of mkF32: cast[int64](float64(cast[ptr float32](addr ret)[]))
      else: cast[int64](ret)
    st[int64](res, v)
