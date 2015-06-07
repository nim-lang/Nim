# -----------------------------------------------------------------*-C-*-
#   libffi 3.0.10 - Copyright (c) 2011 Anthony Green
#                    - Copyright (c) 1996-2003, 2007, 2008 Red Hat, Inc.
#
#   Permission is hereby granted, free of charge, to any person
#   obtaining a copy of this software and associated documentation
#   files (the ``Software''), to deal in the Software without
#   restriction, including without limitation the rights to use, copy,
#   modify, merge, publish, distribute, sublicense, and/or sell copies
#   of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be
#   included in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
#   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#
#   ----------------------------------------------------------------------- 

{.deadCodeElim: on.}

when defined(windows):
  # on Windows we don't use a DLL but instead embed libffi directly:
  {.pragma: mylib, header: r"ffi.h".}

  #{.compile: r"common\malloc_closure.c".}
  {.compile: r"common\raw_api.c".}
  when defined(vcc):
    {.compile: r"msvc\ffi.c".}
    {.compile: r"msvc\prep_cif.c".}
    {.compile: r"msvc\win32.c".}
    {.compile: r"msvc\types.c".}
    when defined(cpu64):
      {.compile: r"msvc\win64_asm.asm".}
    else:
      {.compile: r"msvc\win32_asm.asm".}
  else:
    {.compile: r"gcc\ffi.c".}
    {.compile: r"gcc\prep_cif.c".}
    {.compile: r"gcc\types.c".}
    {.compile: r"gcc\closures.c".}
    when defined(cpu64):
      {.compile: r"gcc\ffi64.c".}
      {.compile: r"gcc\win64_asm.S".}
    else:
      {.compile: r"gcc\win32_asm.S".}

elif defined(macosx):
  {.pragma: mylib, dynlib: "libffi.dylib".}
else:
  {.pragma: mylib, dynlib: "libffi.so".}

type
  Arg* = int
  SArg* = int
{.deprecated: [TArg: Arg, TSArg: SArg].}

when defined(windows) and defined(x86):
  type
    TABI* {.size: sizeof(cint).} = enum
      FIRST_ABI, SYSV, STDCALL

  const DEFAULT_ABI* = SYSV
elif defined(amd64) and defined(windows):
  type 
    TABI* {.size: sizeof(cint).} = enum 
      FIRST_ABI, WIN64
  const DEFAULT_ABI* = WIN64
else:
  type 
    TABI* {.size: sizeof(cint).} = enum
      FIRST_ABI, SYSV, UNIX64

  when defined(i386):
    const DEFAULT_ABI* = SYSV
  else: 
    const DEFAULT_ABI* = UNIX64
    
const 
  tkVOID* = 0
  tkINT* = 1
  tkFLOAT* = 2
  tkDOUBLE* = 3
  tkLONGDOUBLE* = 4
  tkUINT8* = 5
  tkSINT8* = 6
  tkUINT16* = 7
  tkSINT16* = 8
  tkUINT32* = 9
  tkSINT32* = 10
  tkUINT64* = 11
  tkSINT64* = 12
  tkSTRUCT* = 13
  tkPOINTER* = 14

  tkLAST = tkPOINTER
  tkSMALL_STRUCT_1B* = (tkLAST + 1)
  tkSMALL_STRUCT_2B* = (tkLAST + 2)
  tkSMALL_STRUCT_4B* = (tkLAST + 3)

type
  Type* = object
    size*: int
    alignment*: uint16
    typ*: uint16
    elements*: ptr ptr Type
{.deprecated: [TType: Type].}

var
  type_void* {.importc: "ffi_type_void", mylib.}: Type
  type_uint8* {.importc: "ffi_type_uint8", mylib.}: Type
  type_sint8* {.importc: "ffi_type_sint8", mylib.}: Type
  type_uint16* {.importc: "ffi_type_uint16", mylib.}: Type
  type_sint16* {.importc: "ffi_type_sint16", mylib.}: Type
  type_uint32* {.importc: "ffi_type_uint32", mylib.}: Type
  type_sint32* {.importc: "ffi_type_sint32", mylib.}: Type
  type_uint64* {.importc: "ffi_type_uint64", mylib.}: Type
  type_sint64* {.importc: "ffi_type_sint64", mylib.}: Type
  type_float* {.importc: "ffi_type_float", mylib.}: Type
  type_double* {.importc: "ffi_type_double", mylib.}: Type
  type_pointer* {.importc: "ffi_type_pointer", mylib.}: Type
  type_longdouble* {.importc: "ffi_type_longdouble", mylib.}: Type

type 
  Status* {.size: sizeof(cint).} = enum 
    OK, BAD_TYPEDEF, BAD_ABI
  TypeKind* = cuint
  TCif* {.pure, final.} = object 
    abi*: TABI
    nargs*: cuint
    arg_types*: ptr ptr Type
    rtype*: ptr Type
    bytes*: cuint
    flags*: cuint
{.deprecated: [Tstatus: Status].}

type
  Raw* = object 
    sint*: SArg
{.deprecated: [TRaw: Raw].}

proc raw_call*(cif: var Tcif; fn: proc () {.cdecl.}; rvalue: pointer; 
               avalue: ptr Raw) {.cdecl, importc: "ffi_raw_call", mylib.}
proc ptrarray_to_raw*(cif: var Tcif; args: ptr pointer; raw: ptr Raw) {.cdecl, 
    importc: "ffi_ptrarray_to_raw", mylib.}
proc raw_to_ptrarray*(cif: var Tcif; raw: ptr Raw; args: ptr pointer) {.cdecl, 
    importc: "ffi_raw_to_ptrarray", mylib.}
proc raw_size*(cif: var Tcif): int {.cdecl, importc: "ffi_raw_size", mylib.}

proc prep_cif*(cif: var Tcif; abi: TABI; nargs: cuint; rtype: ptr Type; 
               atypes: ptr ptr Type): Status {.cdecl, importc: "ffi_prep_cif", 
    mylib.}
proc call*(cif: var Tcif; fn: proc () {.cdecl.}; rvalue: pointer; 
           avalue: ptr pointer) {.cdecl, importc: "ffi_call", mylib.}

# the same with an easier interface:
type
  ParamList* = array[0..100, ptr Type]
  ArgList* = array[0..100, pointer]
{.deprecated: [TParamList: ParamList, TArgList: ArgList].}

proc prep_cif*(cif: var Tcif; abi: TABI; nargs: cuint; rtype: ptr Type; 
               atypes: ParamList): Status {.cdecl, importc: "ffi_prep_cif",
    mylib.}
proc call*(cif: var Tcif; fn, rvalue: pointer;
           avalue: ArgList) {.cdecl, importc: "ffi_call", mylib.}

# Useful for eliminating compiler warnings 
##define FFI_FN(f) ((void (*)(void))f)
