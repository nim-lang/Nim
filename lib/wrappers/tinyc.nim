#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  CcState {.pure, final.} = object
  PccState* = ptr CcState

  ErrorFunc* = proc (opaque: pointer, msg: cstring) {.cdecl.}

proc openCCState*(): PccState {.importc: "tcc_new", cdecl.}
  ## create a new TCC compilation context

proc closeCCState*(s: PccState) {.importc: "tcc_delete", cdecl.}
  ## free a TCC compilation context

proc setErrorFunc*(s: PccState, errorOpaque: pointer, errorFun: ErrorFunc) {.
  cdecl, importc: "tcc_set_error_func".}
  ## set error/warning display callback

proc setOptions*(s: PccState, options: cstring) {.cdecl, importc: "tcc_set_options".}
  ## set a options

# preprocessor

proc addIncludePath*(s: PccState, pathname: cstring) {.cdecl,
  importc: "tcc_add_include_path".}
  ## add include path

proc addSysincludePath*(s: PccState, pathname: cstring) {.cdecl,
  importc: "tcc_add_sysinclude_path".}
  ## add in system include path

proc defineSymbol*(s: PccState, sym, value: cstring) {.cdecl,
  importc: "tcc_define_symbol".}
  ## define preprocessor symbol 'sym'. Can put optional value

proc undefineSymbol*(s: PccState, sym: cstring) {.cdecl,
  importc: "tcc_undefine_symbol".}
  ## undefine preprocess symbol 'sym'

# compiling

proc addFile*(s: PccState, filename: cstring): cint {.cdecl,
  importc: "tcc_add_file".}
  ## add a file (either a C file, dll, an object, a library or an ld
  ## script). Return -1 if error.

proc compileString*(s: PccState, buf: cstring): cint {.cdecl,
  importc: "tcc_compile_string".}
  ## compile a string containing a C source. Return non zero if error.

# linking commands


const
  OutputMemory*: cint = 1 ## output will be ran in memory (no
                          ## output file) (default)
  OutputExe*: cint = 2 ## executable file
  OutputDll*: cint = 3 ## dynamic library
  OutputObj*: cint = 4 ## object file
  OutputPreprocess*: cint = 5 ## preprocessed file (used internally)

proc setOutputType*(s: PccState, outputType: cint): cint {.cdecl,
  importc: "tcc_set_output_type".}
  ## set output type. MUST BE CALLED before any compilation

proc addLibraryPath*(s: PccState, pathname: cstring): cint {.cdecl,
  importc: "tcc_add_library_path".}
  ## equivalent to -Lpath option

proc addLibrary*(s: PccState, libraryname: cstring): cint {.cdecl,
  importc: "tcc_add_library".}
  ## the library name is the same as the argument of the '-l' option

proc addSymbol*(s: PccState, name: cstring, val: pointer): cint {.cdecl,
  importc: "tcc_add_symbol".}
  ## add a symbol to the compiled program

proc outputFile*(s: PccState, filename: cstring): cint {.cdecl,
  importc: "tcc_output_file".}
  ## output an executable, library or object file. DO NOT call
  ## tcc_relocate() before.

proc run*(s: PccState, argc: cint, argv: cstringArray): cint {.cdecl,
  importc: "tcc_run".}
  ## link and run main() function and return its value. DO NOT call
  ## tcc_relocate() before.

proc relocate*(s: PccState, p: pointer): cint {.cdecl,
  importc: "tcc_relocate".}
  ## copy code into memory passed in by the caller and do all relocations
  ## (needed before using tcc_get_symbol()).
  ## returns -1 on error and required size if ptr is NULL

proc getSymbol*(s: PccState, name: cstring): pointer {.cdecl,
  importc: "tcc_get_symbol".}
  ## return symbol value or NULL if not found

proc setLibPath*(s: PccState, path: cstring) {.cdecl,
  importc: "tcc_set_lib_path".}
  ## set CONFIG_TCCDIR at runtime
