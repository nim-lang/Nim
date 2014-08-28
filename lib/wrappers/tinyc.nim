#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  TccState {.pure, final.} = object
  PccState* = ptr TccState
  
  TErrorFunc* = proc (opaque: pointer, msg: cstring) {.cdecl.}

proc openCCState*(): PccState {.importc: "tcc_new", cdecl.}
  ## create a new TCC compilation context

proc closeCCState*(s: PccState) {.importc: "tcc_delete", cdecl.}
  ## free a TCC compilation context

proc enableDebug*(s: PccState) {.importc: "tcc_enable_debug", cdecl.}
  ## add debug information in the generated code

proc setErrorFunc*(s: PccState, errorOpaque: pointer, errorFun: TErrorFunc) {.
  cdecl, importc: "tcc_set_error_func".}
  ## set error/warning display callback

proc setWarning*(s: PccState, warningName: cstring, value: int) {.cdecl,
  importc: "tcc_set_warning".}
  ## set/reset a warning

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
  OutputMemory*: cint = 0 ## output will be ran in memory (no
                          ## output file) (default)
  OutputExe*: cint = 1 ## executable file
  OutputDll*: cint = 2 ## dynamic library
  OutputObj*: cint = 3 ## object file
  OutputPreprocess*: cint = 4 ## preprocessed file (used internally)
  
  OutputFormatElf*: cint = 0 ## default output format: ELF
  OutputFormatBinary*: cint = 1 ## binary image output
  OutputFormatCoff*: cint = 2 ## COFF

proc setOutputType*(s: PCCState, outputType: cint): cint {.cdecl, 
  importc: "tcc_set_output_type".}
  ## set output type. MUST BE CALLED before any compilation

proc addLibraryPath*(s: PccState, pathname: cstring): cint {.cdecl,
  importc: "tcc_add_library_path".}
  ## equivalent to -Lpath option

proc addLibrary*(s: PCCState, libraryname: cstring): cint {.cdecl,
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
  

