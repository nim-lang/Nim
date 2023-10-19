## A pure C API to enable client code to embed GCC as a JIT-compiler.
## Copyright (C) 2013-2023 Free Software Foundation, Inc.
##
## This file is part of GCC.
##
## GCC is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3, or (at your option)
## any later version.
##
## GCC is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with GCC; see the file COPYING3. If not see
## <http://www.gnu.org/licenses/>.

const
  gccdll* = "/opt/homebrew/lib/gcc/13/libgccjit.dylib"

## ********************************************************************
## Data structures.
## ********************************************************************
## All structs within the API are opaque.
## A gcc_jit_context encapsulates the state of a compilation.
## You can set up options on it, and add types, functions and code, using
## the API below.
##
## Invoking gcc_jit_context_compile on it gives you a gcc_jit_result *
## (or NULL), representing in-memory machine code.
##
## You can call gcc_jit_context_compile repeatedly on one context, giving
## multiple independent results.
##
## Similarly, you can call gcc_jit_context_compile_to_file on a context
## to compile to disk.
##
## Eventually you can call gcc_jit_context_release to clean up the
## context; any in-memory results created from it are still usable, and
## should be cleaned up via gcc_jit_result_release.

## An object created within a context. Such objects are automatically
## cleaned up when the context is released.
##
## The class hierarchy looks like this:
##
## +- gcc_jit_object
## 	 +- gcc_jit_location
## 	 +- gcc_jit_type
## 	    +- gcc_jit_struct
## 	    +- gcc_jit_function_type
## 	    +- gcc_jit_vector_type
## 	 +- gcc_jit_field
## 	 +- gcc_jit_function
## 	 +- gcc_jit_block
## 	 +- gcc_jit_rvalue
## 	     +- gcc_jit_lvalue
## 	   +- gcc_jit_param
## 	 +- gcc_jit_case
## 	 +- gcc_jit_extended_asm

type
  GContext* {.bycopy.} = object
  GResult* {.bycopy.} = object ## A gcc_jit_result encapsulates the result of an in-memory compilation.

  GObject* {.bycopy.} = object

  GLocation* {.bycopy.} = object ## \
    ## A gcc_jit_location encapsulates a source code location, so that
    ## you can (optionally) associate locations in your language with
    ## statements in the JIT-compiled code, allowing the debugger to
    ## single-step through your language.
    ##
    ## Note that to do so, you also need to enable
    ## GCC_JIT_BOOL_OPTION_DEBUGINFO
    ## on the gcc_jit_context.
    ##
    ## gcc_jit_location instances are optional; you can always pass
    ## NULL.
  GType* {.bycopy.} = object ## \
    ## A gcc_jit_type encapsulates a type e.g. "int" or a "struct foo*".
  Field* {.bycopy.} = object ## \
    ## A gcc_jit_field encapsulates a field within a struct; it is used
    ## when creating a struct type (using gcc_jit_context_new_struct_type).
    ## Fields cannot be shared between structs.
  Struct* {.bycopy.} = object ## \
    ## A gcc_jit_struct encapsulates a struct type, either one that we have
    ## the layout for, or an opaque type.
  FunctionType* {.bycopy.} = object ## \
    ## A gcc_jit_function_type encapsulates a function type.
  VectorType* {.bycopy.} = object ## \
    ## A gcc_jit_vector_type encapsulates a vector type.
  Function* {.bycopy.} = object ## \
    ## A gcc_jit_function encapsulates a function: either one that you're
    ## creating yourself, or a reference to one that you're dynamically
    ## linking to within the rest of the process.
  GBlock* {.bycopy.} = object ## \
    ## A gcc_jit_block encapsulates a "basic block" of statements within a
    ## function (i.e. with one entry point and one exit point).
    ##
    ## Every block within a function must be terminated with a conditional,
    ## a branch, or a return.
    ##
    ## The blocks within a function form a directed graph.
    ##
    ## The entrypoint to the function is the first block created within
    ## it.
    ##
    ## All of the blocks in a function must be reachable via some path from
    ## the first block.
    ##
    ## It's OK to have more than one "return" from a function (i.e. multiple
    ## blocks that terminate by returning).
  Rvalue* {.bycopy.} = object ## \
    ## A gcc_jit_rvalue is an expression within your code, with some type.
  Lvalue* {.bycopy.} = object ## \
    ## A gcc_jit_lvalue is a storage location within your code (e.g. a
    ## variable, a parameter, etc). It is also a gcc_jit_rvalue; use
    ## gcc_jit_lvalue_as_rvalue to cast.
  Param* {.bycopy.} = object ## \
    ## A gcc_jit_param is a function parameter, used when creating a
    ## gcc_jit_function. It is also a gcc_jit_lvalue (and thus also an
    ## rvalue); use gcc_jit_param_as_lvalue to convert.
  GCase* {.bycopy.} = object ## \
    ## A gcc_jit_case is for use when building multiway branches via
    ## gcc_jit_block_end_with_switch and represents a range of integer
    ## values (or an individual integer value) together with an associated
    ## destination block.
  ExtendedAsm* {.bycopy.} = object ## \
    ## A gcc_jit_extended_asm represents an assembly language statement,
    ## analogous to an extended "asm" statement in GCC's C front-end: a series
    ## of low-level instructions inside a function that convert inputs to
    ## outputs.

proc contextAcquire*(): ptr GContext {.cdecl, importc: "gcc_jit_context_acquire",
                                      dynlib: gccdll.}
  ## Acquire a JIT-compilation context.

proc contextRelease*(ctxt: ptr GContext) {.cdecl,
    importc: "gcc_jit_context_release", dynlib: gccdll.}
  ## Release the context. After this call, it's no longer valid to use
  ## the ctxt.


## Options present in the initial release of libgccjit.
## These were handled using enums.
## Options taking string values.

type
  StrOption* {.size: sizeof(cint).} = enum ## The name of the program, for use as a prefix when printing error
                                            ## messages to stderr. If NULL, or default, "libgccjit.so" is used.
    STR_OPTION_PROGNAME, NUM_STR_OPTIONS


## Options taking int values.

type
  IntOption* {.size: sizeof(cint).} = enum ## How much to optimize the code.
                                            ## Valid values are 0-3, corresponding to GCC's command-line options
                                            ## -O0 through -O3.
                                            ##
                                            ## The default value is 0 (unoptimized).
    INT_OPTION_OPTIMIZATION_LEVEL, NUM_INT_OPTIONS


## Options taking boolean values.
## These all default to "false".

type
  BoolOption* {.size: sizeof(cint).} = enum  ## If true, gcc_jit_context_compile will attempt to do the right
                                             ## thing so that if you attach a debugger to the process, it will
                                             ## be able to inspect variables and step through your code.
                                             ##
                                             ## Note that you can't step through code unless you set up source
                                             ## location information for the code (by creating and passing in
                                             ## gcc_jit_location instances).
    BOOL_OPTION_DEBUGINFO,  ## If true, gcc_jit_context_compile will dump its initial "tree"
                            ## representation of your code to stderr (before any
                            ## optimizations).
    BOOL_OPTION_DUMP_INITIAL_TREE,  ## If true, gcc_jit_context_compile will dump the "gimple"
                                    ## representation of your code to stderr, before any optimizations
                                    ## are performed. The dump resembles C code.
    BOOL_OPTION_DUMP_INITIAL_GIMPLE,  ## If true, gcc_jit_context_compile will dump the final
                                      ## generated code to stderr, in the form of assembly language.
    BOOL_OPTION_DUMP_GENERATED_CODE,  ## If true, gcc_jit_context_compile will print information to stderr
                                      ## on the actions it is performing, followed by a profile showing
                                      ## the time taken and memory usage of each phase.
                                      ##
    BOOL_OPTION_DUMP_SUMMARY,  ## If true, gcc_jit_context_compile will dump copious
                               ## amount of information on what it's doing to various
                               ## files within a temporary directory. Use
                               ## GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES (see below) to
                               ## see the results. The files are intended to be human-readable,
                               ## but the exact files and their formats are subject to change.
                               ##
    BOOL_OPTION_DUMP_EVERYTHING,  ## If true, libgccjit will aggressively run its garbage collector, to
                                  ## shake out bugs (greatly slowing down the compile). This is likely
                                  ## to only be of interest to developers *of* the library. It is
                                  ## used when running the selftest suite.
    BOOL_OPTION_SELFCHECK_GC,  ## If true, gcc_jit_context_release will not clean up
                               ## intermediate files written to the filesystem, and will display
                               ## their location on stderr.
    BOOL_OPTION_KEEP_INTERMEDIATES, NUM_BOOL_OPTIONS


## Set a string option on the given context.
##
## The context takes a copy of the string, so the
## (const char *) buffer is not needed anymore after the call
## returns.

proc contextSetStrOption*(ctxt: ptr GContext; opt: StrOption; value: cstring) {.
    cdecl, importc: "gcc_jit_context_set_str_option", dynlib: gccdll.}
## Set an int option on the given context.

proc contextSetIntOption*(ctxt: ptr GContext; opt: IntOption; value: cint) {.
    cdecl, importc: "gcc_jit_context_set_int_option", dynlib: gccdll.}
## Set a boolean option on the given context.
##
## Zero is "false" (the default), non-zero is "true".

proc contextSetBoolOption*(ctxt: ptr GContext; opt: BoolOption; value: cint) {.
    cdecl, importc: "gcc_jit_context_set_bool_option", dynlib: gccdll.}
## Options added after the initial release of libgccjit.
## These are handled by providing an entrypoint per option,
## rather than by extending the enum gcc_jit_*_option,
## so that client code that use these new options can be identified
## from binary metadata.
## By default, libgccjit will issue an error about unreachable blocks
## within a function.
##
## This option can be used to disable that error.
##
## This entrypoint was added in LIBGCCJIT_ABI_2; you can test for
## its presence using
## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_set_bool_allow_unreachable_blocks
##

proc contextSetBoolAllowUnreachableBlocks*(ctxt: ptr GContext; boolValue: cint) {.
    cdecl, importc: "gcc_jit_context_set_bool_allow_unreachable_blocks",
    dynlib: gccdll.}
## Pre-canned feature macro to indicate the presence of
## gcc_jit_context_set_bool_allow_unreachable_blocks. This can be
## tested for with #ifdef.

## By default, libgccjit will print errors to stderr.
##
## This option can be used to disable the printing.
##
## This entrypoint was added in LIBGCCJIT_ABI_23; you can test for
## its presence using
## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_set_bool_print_errors_to_stderr
##

proc contextSetBoolPrintErrorsToStderr*(ctxt: ptr GContext; enabled: cint) {.
    cdecl, importc: "gcc_jit_context_set_bool_print_errors_to_stderr",
    dynlib: gccdll.}
## Pre-canned feature macro to indicate the presence of
## gcc_jit_context_set_bool_print_errors_to_stderr. This can be
## tested for with #ifdef.

## Implementation detail:
## libgccjit internally generates assembler, and uses "driver" code
## for converting it to other formats (e.g. shared libraries).
##
## By default, libgccjit will use an embedded copy of the driver
## code.
##
## This option can be used to instead invoke an external driver executable
## as a subprocess.
##
## This entrypoint was added in LIBGCCJIT_ABI_5; you can test for
## its presence using
## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_set_bool_use_external_driver
##

proc contextSetBoolUseExternalDriver*(ctxt: ptr GContext; boolValue: cint) {.
    cdecl, importc: "gcc_jit_context_set_bool_use_external_driver",
    dynlib: gccdll.}

proc contextAddCommandLineOption*(ctxt: ptr GContext; optname: cstring) {.cdecl,
    importc: "gcc_jit_context_add_command_line_option", dynlib: gccdll.}
  ## Add an arbitrary gcc command-line option to the context.
  ## The context takes a copy of the string, so the
  ## (const char *) optname is not needed anymore after the call
  ## returns.
  ##
  ## Note that only some options are likely to be meaningful; there is no
  ## "frontend" within libgccjit, so typically only those affecting
  ## optimization and code-generation are likely to be useful.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_1; you can test for
  ## its presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_add_command_line_option


proc contextAddDriverOption*(ctxt: ptr GContext; optname: cstring) {.cdecl,
    importc: "gcc_jit_context_add_driver_option", dynlib: gccdll.}
  ## Add an arbitrary gcc driver option to the context.
  ## The context takes a copy of the string, so the
  ## (const char *) optname is not needed anymore after the call
  ## returns.
  ##
  ## Note that only some options are likely to be meaningful; there is no
  ## "frontend" within libgccjit, so typically only those affecting
  ## assembler and linker are likely to be useful.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_11; you can test for
  ## its presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_add_driver_option


proc contextCompile*(ctxt: ptr GContext): ptr GResult {.cdecl,
    importc: "gcc_jit_context_compile", dynlib: gccdll.}
  ## Compile the context to in-memory machine code.
  ##
  ## This can be called more that once on a given context,
  ## although any errors that occur will block further compilation.

type
  OutputKind* {.size: sizeof(cint).} = enum ## Kinds of ahead-of-time compilation, for use with
                                            ## gcc_jit_context_compile_to_file.
    OUTPUT_KIND_ASSEMBLER, ## Compile the context to an assembler file.
    OUTPUT_KIND_OBJECT_FILE, ## Compile the context to an object file.
    OUTPUT_KIND_DYNAMIC_LIBRARY, ## Compile the context to a dynamic library.
    OUTPUT_KIND_EXECUTABLE ## Compile the context to an executable.

proc contextCompileToFile*(ctxt: ptr GContext; outputKind: OutputKind;
                           outputPath: cstring) {.cdecl,
    importc: "gcc_jit_context_compile_to_file", dynlib: gccdll.}
  ## Compile the context to a file of the given kind.
  ##
  ## This can be called more that once on a given context,
  ## although any errors that occur will block further compilation.

proc contextDumpToFile*(ctxt: ptr GContext; path: cstring; updateLocations: cint) {.
    cdecl, importc: "gcc_jit_context_dump_to_file", dynlib: gccdll.}
  ## To help with debugging: dump a C-like representation to the given path,
  ## describing what's been set up on the context.
  ##
  ## If "update_locations" is true, then also set up gcc_jit_location
  ## information throughout the context, pointing at the dump file as if it
  ## were a source file. This may be of use in conjunction with
  ## GCC_JIT_BOOL_OPTION_DEBUGINFO to allow stepping through the code in a
  ## debugger.


proc contextSetLogfile*(ctxt: ptr GContext; logfile: ptr File; flags: cint;
                        verbosity: cint) {.cdecl,
    importc: "gcc_jit_context_set_logfile", dynlib: gccdll.}
  ## To help with debugging; enable ongoing logging of the context's
  ## activity to the given FILE *.
  ##
  ## The caller remains responsible for closing "logfile".
  ##
  ## Params "flags" and "verbosity" are reserved for future use, and
  ## must both be 0 for now.


proc contextGetFirstError*(ctxt: ptr GContext): cstring {.cdecl,
    importc: "gcc_jit_context_get_first_error", dynlib: gccdll.}
  ## To be called after any API call, this gives the first error message
  ## that occurred on the context.
  ##
  ## The returned string is valid for the rest of the lifetime of the
  ## context.
  ##
  ## If no errors occurred, this will be NULL.


proc contextGetLastError*(ctxt: ptr GContext): cstring {.cdecl,
    importc: "gcc_jit_context_get_last_error", dynlib: gccdll.}
  ## To be called after any API call, this gives the last error message
  ## that occurred on the context.
  ##
  ## If no errors occurred, this will be NULL.
  ##
  ## If non-NULL, the returned string is only guaranteed to be valid until
  ## the next call to libgccjit relating to this context.



proc resultGetCode*(result: ptr GResult; funcname: cstring): pointer {.cdecl,
    importc: "gcc_jit_result_get_code", dynlib: gccdll.}
  ## Locate a given function within the built machine code.
  ## This will need to be cast to a function pointer of the
  ## correct type before it can be called.


## Locate a given global within the built machine code.
## It must have been created using GCC_JIT_GLOBAL_EXPORTED.
## This is a ptr to the global, so e.g. for an int this is an int *.

proc resultGetGlobal*(result: ptr GResult; name: cstring): pointer {.cdecl,
    importc: "gcc_jit_result_get_global", dynlib: gccdll.}
## Once we're done with the code, this unloads the built .so file.
## This cleans up the result; after calling this, it's no longer
## valid to use the result.

proc resultRelease*(result: ptr GResult) {.cdecl,
    importc: "gcc_jit_result_release", dynlib: gccdll.}
## ********************************************************************
## Functions for creating "contextual" objects.
##
## All objects created by these functions share the lifetime of the context
## they are created within, and are automatically cleaned up for you when
## you call gcc_jit_context_release on the context.
##
## Note that this means you can't use references to them after you've
## released their context.
##
## All (const char *) string arguments passed to these functions are
## copied, so you don't need to keep them around.
##
## You create code by adding a sequence of statements to blocks.
## ********************************************************************
## ********************************************************************
## The base class of "contextual" object.
## ********************************************************************
## Which context is "obj" within?

proc objectGetContext*(obj: ptr GObject): ptr GContext {.cdecl,
    importc: "gcc_jit_object_get_context", dynlib: gccdll.}
## Get a human-readable description of this object.
## The string buffer is created the first time this is called on a given
## object, and persists until the object's context is released.

proc objectGetDebugString*(obj: ptr GObject): cstring {.cdecl,
    importc: "gcc_jit_object_get_debug_string", dynlib: gccdll.}
## ********************************************************************
## Debugging information.
## ********************************************************************
## Creating source code locations for use by the debugger.
## Line and column numbers are 1-based.

proc contextNewLocation*(ctxt: ptr GContext; filename: cstring; line: cint;
                         column: cint): ptr GLocation {.cdecl,
    importc: "gcc_jit_context_new_location", dynlib: gccdll.}
## Upcasting from location to object.

proc locationAsObject*(loc: ptr GLocation): ptr GObject {.cdecl,
    importc: "gcc_jit_location_as_object", dynlib: gccdll.}
## ********************************************************************
## Types.
## ********************************************************************
## Upcasting from type to object.

proc typeAsObject*(`type`: ptr GType): ptr GObject {.cdecl,
    importc: "gcc_jit_type_as_object", dynlib: gccdll.}

type
  Types* {.size: sizeof(cint).} = enum ## C's "void" type.
    TYPE_VOID,              ## "void *".
    TYPE_VOID_PTR, ## C++'s bool type; also C99's "_Bool" type, aka "bool" if using
                    ## stdbool.h.
    TYPE_BOOL, ## Various integer types.
                ## C's "char" (of some signedness) and the variants where the
                ## signedness is specified.
    TYPE_CHAR, TYPE_SIGNED_CHAR, TYPE_UNSIGNED_CHAR, ## C's "short" and "unsigned short".
    TYPE_SHORT,             ## signed
    TYPE_UNSIGNED_SHORT,    ## C's "int" and "unsigned int".
    TYPE_INT,               ## signed
    TYPE_UNSIGNED_INT,      ## C's "long" and "unsigned long".
    TYPE_LONG,              ## signed
    TYPE_UNSIGNED_LONG,     ## C99's "long long" and "unsigned long long".
    TYPE_LONG_LONG,         ## signed
    TYPE_UNSIGNED_LONG_LONG, ## Floating-point types
    TYPE_FLOAT, TYPE_DOUBLE, TYPE_LONG_DOUBLE, ## C type: (const char *).
    TYPE_CONST_CHAR_PTR,    ## The C "size_t" type.
    TYPE_SIZE_T,            ## C type: (FILE *)
    TYPE_FILE_PTR,          ## Complex numbers.
    TYPE_COMPLEX_FLOAT, TYPE_COMPLEX_DOUBLE, TYPE_COMPLEX_LONG_DOUBLE, ## Sized integer types.
    TYPE_UINT8_T, TYPE_UINT16_T, TYPE_UINT32_T, TYPE_UINT64_T, TYPE_UINT128_T,
    TYPE_INT8_T, TYPE_INT16_T, TYPE_INT32_T, TYPE_INT64_T, TYPE_INT128_T


proc contextGetType*(ctxt: ptr GContext; `type`: Types): ptr GType {.cdecl,
    importc: "gcc_jit_context_get_type", dynlib: gccdll.}
  ## Access to specific types.

proc contextGetIntType*(ctxt: ptr GContext; numBytes: cint; isSigned: cint): ptr GType {.
    cdecl, importc: "gcc_jit_context_get_int_type", dynlib: gccdll.}
  ## Get the integer type of the given size and signedness.


proc typeGetPointer*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_get_pointer", dynlib: gccdll.}
  ## Constructing new types.
  ## Given type "T", get type "T*".

proc typeGetConst*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_get_const", dynlib: gccdll.}
  ## Given type "T", get type "const T".

proc typeGetVolatile*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_get_volatile", dynlib: gccdll.}
  ## Given type "T", get type "volatile T".

proc compatibleTypes*(ltype: ptr GType; rtype: ptr GType): cint {.cdecl,
    importc: "gcc_jit_compatible_types", dynlib: gccdll.}
  ## Given types LTYPE and RTYPE, return non-zero if they are compatible.
  ## This API entrypoint was added in LIBGCCJIT_ABI_20; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_SIZED_INTEGERS

proc typeGetSize*(`type`: ptr GType): int {.cdecl,
    importc: "gcc_jit_type_get_size", dynlib: gccdll.}
  ## Given type "T", get its size.
  ## This API entrypoint was added in LIBGCCJIT_ABI_20; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_SIZED_INTEGERS


proc contextNewArrayType*(ctxt: ptr GContext; loc: ptr GLocation;
                          elementType: ptr GType; numElements: cint): ptr GType {.
    cdecl, importc: "gcc_jit_context_new_array_type", dynlib: gccdll.}
  ## Given type "T", get type "T[N]" (for a constant N).

proc contextNewField*(ctxt: ptr GContext; loc: ptr GLocation; `type`: ptr GType;
                      name: cstring): ptr Field {.cdecl,
    importc: "gcc_jit_context_new_field", dynlib: gccdll.}
  ## Struct-handling.
  ## Create a field, for use within a struct or union.

proc contextNewBitfield*(ctxt: ptr GContext; loc: ptr GLocation; `type`: ptr GType;
                         width: cint; name: cstring): ptr Field {.cdecl,
    importc: "gcc_jit_context_new_bitfield", dynlib: gccdll.}
  ## Create a bit field, for use within a struct or union.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_12; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_new_bitfield

proc fieldAsObject*(field: ptr Field): ptr GObject {.cdecl,
    importc: "gcc_jit_field_as_object", dynlib: gccdll.}
  ## Upcasting from field to object.

proc contextNewStructType*(ctxt: ptr GContext; loc: ptr GLocation; name: cstring;
                           numFields: cint; fields: ptr UncheckedArray[ptr Field]): ptr Struct {.
    cdecl, importc: "gcc_jit_context_new_struct_type", dynlib: gccdll.}
  ## Create a struct type from an array of fields.

proc contextNewOpaqueStruct*(ctxt: ptr GContext; loc: ptr GLocation; name: cstring): ptr Struct {.
    cdecl, importc: "gcc_jit_context_new_opaque_struct", dynlib: gccdll.}
  ## Create an opaque struct type.

proc structAsType*(structType: ptr Struct): ptr GType {.cdecl,
    importc: "gcc_jit_struct_as_type", dynlib: gccdll.}
  ## Upcast a struct to a type.


proc structSetFields*(structType: ptr Struct; loc: ptr GLocation;
                      numFields: cint; fields: ptr UncheckedArray[ptr Field]) {.cdecl,
    importc: "gcc_jit_struct_set_fields", dynlib: gccdll.}
  ## Populating the fields of a formerly-opaque struct type.
  ## This can only be called once on a given struct type.


proc structGetField*(structType: ptr Struct; index: csize_t): ptr Field {.cdecl,
    importc: "gcc_jit_struct_get_field", dynlib: gccdll.}
  ## Get a field by index.


proc structGetFieldCount*(structType: ptr Struct): csize_t {.cdecl,
    importc: "gcc_jit_struct_get_field_count", dynlib: gccdll.}
  ## Get the number of fields.

proc contextNewUnionType*(ctxt: ptr GContext; loc: ptr GLocation; name: cstring;
                          numFields: cint; fields: ptr UncheckedArray[ptr Field]): ptr GType {.
    cdecl, importc: "gcc_jit_context_new_union_type", dynlib: gccdll.}
  ## Unions work similarly to structs.

proc contextNewFunctionPtrType*(ctxt: ptr GContext; loc: ptr GLocation;
                                returnType: ptr GType; numParams: cint;
                                paramTypes: ptr UncheckedArry[ptr GType]; isVariadic: cint): ptr GType {.
    cdecl, importc: "gcc_jit_context_new_function_ptr_type", dynlib: gccdll.}
  ## Function pointers.


## ********************************************************************
## Constructing functions.
## ********************************************************************

proc contextNewParam*(ctxt: ptr GContext; loc: ptr GLocation; `type`: ptr GType;
                      name: cstring): ptr Param {.cdecl,
    importc: "gcc_jit_context_new_param", dynlib: gccdll.}
  ## Create a function param.

proc paramAsObject*(param: ptr Param): ptr GObject {.cdecl,
    importc: "gcc_jit_param_as_object", dynlib: gccdll.}
  ## Upcasting from param to object.


proc paramAsLvalue*(param: ptr Param): ptr Lvalue {.cdecl,
    importc: "gcc_jit_param_as_lvalue", dynlib: gccdll.}
  ## Upcasting from param to lvalue.


proc paramAsRvalue*(param: ptr Param): ptr Rvalue {.cdecl,
    importc: "gcc_jit_param_as_rvalue", dynlib: gccdll.}
  ## Upcasting from param to rvalue.

type
  FunctionKind* {.size: sizeof(cint).} = enum ## Kinds of function.
    FUNCTION_EXPORTED,  ## Function is defined by the client code and visible
                        ## by name outside of the JIT.
    FUNCTION_INTERNAL,  ## Function is defined by the client code, but is invisible
                        ## outside of the JIT. Analogous to a "static" function.
    FUNCTION_IMPORTED,  ## Function is not defined by the client code; we're merely
                        ## referring to it. Analogous to using an "extern" function from a
                        ## header file.
    FUNCTION_ALWAYS_INLINE ## Function is only ever inlined into other functions, and is
                           ## invisible outside of the JIT.
                           ##
                           ## Analogous to prefixing with "inline" and adding
                           ## __attribute__((always_inline)).
                           ##
                           ## Inlining will only occur when the optimization level is
                           ## above 0; when optimization is off, this is essentially the
                           ## same as GCC_JIT_FUNCTION_INTERNAL.

type
  TlsModel* {.size: sizeof(cint).} = enum ## Thread local storage model.
    TLS_MODEL_NONE, TLS_MODEL_GLOBAL_DYNAMIC, TLS_MODEL_LOCAL_DYNAMIC,
    TLS_MODEL_INITIAL_EXEC, TLS_MODEL_LOCAL_EXEC

proc contextNewFunction*(ctxt: ptr GContext; loc: ptr GLocation;
                         kind: FunctionKind; returnType: ptr GType;
                         name: cstring; numParams: cint; params: ptr UncheckedArray[ptr Param];
                         isVariadic: cint): ptr Function {.cdecl,
    importc: "gcc_jit_context_new_function", dynlib: gccdll.}
  ## Create a function.

proc contextGetBuiltinFunction*(ctxt: ptr GContext; name: cstring): ptr Function {.
    cdecl, importc: "gcc_jit_context_get_builtin_function", dynlib: gccdll.}
  ## Create a reference to a builtin function (sometimes called
  ## intrinsic functions).

proc functionAsObject*(`func`: ptr Function): ptr GObject {.cdecl,
    importc: "gcc_jit_function_as_object", dynlib: gccdll.}
  ## Upcasting from function to object.

proc functionGetParam*(`func`: ptr Function; index: cint): ptr Param {.cdecl,
    importc: "gcc_jit_function_get_param", dynlib: gccdll.}
  ## Get a specific param of a function by index.

proc functionDumpToDot*(`func`: ptr Function; path: cstring) {.cdecl,
    importc: "gcc_jit_function_dump_to_dot", dynlib: gccdll.}
  ## Emit the function in graphviz format.

proc functionNewBlock*(`func`: ptr Function; name: cstring): ptr GBlock {.cdecl,
    importc: "gcc_jit_function_new_block", dynlib: gccdll.}
  ## Create a block.
  ##
  ## The name can be NULL, or you can give it a meaningful name, which
  ## may show up in dumps of the internal representation, and in error
  ## messages.


proc blockAsObject*(`block`: ptr GBlock): ptr GObject {.cdecl,
    importc: "gcc_jit_block_as_object", dynlib: gccdll.}
  ## Upcasting from block to object.

proc blockGetFunction*(`block`: ptr GBlock): ptr Function {.cdecl,
    importc: "gcc_jit_block_get_function", dynlib: gccdll.}
  ## Which function is this block within?

## ********************************************************************
## lvalues, rvalues and expressions.
## ********************************************************************

type
  GlobalKind* {.size: sizeof(cint).} = enum
    GLOBAL_EXPORTED,  ## Global is defined by the client code and visible
                      ## by name outside of this JIT context via gcc_jit_result_get_global.
    GLOBAL_INTERNAL,  ## Global is defined by the client code, but is invisible
                      ## outside of this JIT context. Analogous to a "static" global.
    GLOBAL_IMPORTED   ## Global is not defined by the client code; we're merely
                      ## referring to it. Analogous to using an "extern" global from a
                      ## header file.

proc contextNewGlobal*(ctxt: ptr GContext; loc: ptr GLocation; kind: GlobalKind;
                       `type`: ptr GType; name: cstring): ptr Lvalue {.cdecl,
    importc: "gcc_jit_context_new_global", dynlib: gccdll.}

proc contextNewStructConstructor*(ctxt: ptr GContext; loc: ptr GLocation;
                                  `type`: ptr GType; numValues: csize_t;
                                  fields: ptr UncheckedArray[ptr Field]; values: ptr UncheckedArray[ptr Rvalue]): ptr Rvalue {.
    cdecl, importc: "gcc_jit_context_new_struct_constructor", dynlib: gccdll.}
  ## Create a constructor for a struct as an rvalue.
  ##
  ## Returns NULL on error. The two parameter arrays are copied and
  ## do not have to outlive the context.
  ##
  ## `type` specifies what the constructor will build and has to be
  ## a struct.
  ##
  ## `num_values` specifies the number of elements in `values`.
  ##
  ## `fields` need to have the same length as `values`, or be NULL.
  ##
  ## If `fields` is null, the values are applied in definition order.
  ##
  ## Otherwise, each field in `fields` specifies which field in the struct to
  ## set to the corresponding value in `values`. `fields` and `values`
  ## are paired by index.
  ##
  ## Each value has to have the same unqualified type as the field
  ## it is applied to.
  ##
  ## A NULL value element  in `values` is a shorthand for zero initialization
  ## of the corresponding field.
  ##
  ## The fields in `fields` have to be in definition order, but there
  ## can be gaps. Any field in the struct that is not specified in
  ## `fields` will be zeroed.
  ##
  ## The fields in `fields` need to be the same objects that were used
  ## to create the struct.
  ##
  ## If `num_values` is 0, the array parameters will be
  ## ignored and zero initialization will be used.
  ##
  ## The constructor rvalue can be used for assignment to locals.
  ## It can be used to initialize global variables with
  ## gcc_jit_global_set_initializer_rvalue. It can also be used as a
  ## temporary value for function calls and return values.
  ##
  ## The constructor can contain nested constructors.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_19; you can test for its
  ## presence using:
  ## #ifdef LIBGCCJIT_HAVE_CTORS
  ##


proc contextNewUnionConstructor*(ctxt: ptr GContext; loc: ptr GLocation;
                                 `type`: ptr GType; field: ptr Field;
                                 value: ptr Rvalue): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_union_constructor", dynlib: gccdll.}
  ## Create a constructor for a union as an rvalue.
  ##
  ## Returns NULL on error.
  ##
  ## `type` specifies what the constructor will build and has to be
  ## an union.
  ##
  ## `field` specifies which field to set. If it is NULL, the first
  ## field in the union will be set. `field` need to be the same
  ## object that were used to create the union.
  ##
  ## `value` specifies what value to set the corresponding field to.
  ## If `value` is NULL, zero initialization will be used.
  ##
  ## Each value has to have the same unqualified type as the field
  ## it is applied to.
  ##
  ## `field` need to be the same objects that were used
  ## to create the union.
  ##
  ## The constructor rvalue can be used for assignment to locals.
  ## It can be used to initialize global variables with
  ## gcc_jit_global_set_initializer_rvalue. It can also be used as a
  ## temporary value for function calls and return values.
  ##
  ## The constructor can contain nested constructors.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_19; you can test for its
  ## presence using:
  ## #ifdef LIBGCCJIT_HAVE_CTORS
  ##

proc contextNewArrayConstructor*(ctxt: ptr GContext; loc: ptr GLocation;
                                 `type`: ptr GType; numValues: csize_t;
                                 values: ptr UncheckedArray[ptr Rvalue]): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_array_constructor", dynlib: gccdll.}
  ## Create a constructor for an array as an rvalue.
  ##
  ## Returns NULL on error. `values` are copied and
  ## do not have to outlive the context.
  ##
  ## `type` specifies what the constructor will build and has to be
  ## an array.
  ##
  ## `num_values` specifies the number of elements in `values` and
  ## it can't have more elements than the array type.
  ##
  ## Each value in `values` sets the corresponding value in the array.
  ## If the array type itself has more elements than `values`, the
  ## left-over elements will be zeroed.
  ##
  ## Each value in `values` need to be the same unqualified type as the
  ## array type's element type.
  ##
  ## If `num_values` is 0, the `values` parameter will be
  ## ignored and zero initialization will be used.
  ##
  ## Note that a string literal rvalue can't be used to construct a char
  ## array. It needs one rvalue for each char.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_19; you can test for its
  ## presence using:
  ## #ifdef LIBGCCJIT_HAVE_CTORS
  ##


proc globalSetInitializerRvalue*(global: ptr Lvalue; initValue: ptr Rvalue): ptr Lvalue {.
    cdecl, importc: "gcc_jit_global_set_initializer_rvalue", dynlib: gccdll.}
  ## Set the initial value of a global of any type with an rvalue.
  ##
  ## The rvalue needs to be a constant expression, e.g. no function calls.
  ##
  ## The global can't have the 'kind' GCC_JIT_GLOBAL_IMPORTED.
  ##
  ## Use together with gcc_jit_context_new_constructor () to
  ## initialize structs, unions and arrays.
  ##
  ## On success, returns the 'global' parameter unchanged. Otherwise, NULL.
  ##
  ## 'values' is copied and does not have to outlive the context.
  ##
  ## This entrypoint was added in LIBGCCJIT_ABI_19; you can test for its
  ## presence using:
  ## #ifdef LIBGCCJIT_HAVE_CTORS
  ##



proc globalSetInitializer*(global: ptr Lvalue; blob: pointer; numBytes: csize_t): ptr Lvalue {.
    cdecl, importc: "gcc_jit_global_set_initializer", dynlib: gccdll.}
  ## Set an initial value for a global, which must be an array of
  ## integral type. Return the global itself.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_14; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_global_set_initializer

## Upcasting.

proc lvalueAsObject*(lvalue: ptr Lvalue): ptr GObject {.cdecl,
    importc: "gcc_jit_lvalue_as_object", dynlib: gccdll.}
proc lvalueAsRvalue*(lvalue: ptr Lvalue): ptr Rvalue {.cdecl,
    importc: "gcc_jit_lvalue_as_rvalue", dynlib: gccdll.}
proc rvalueAsObject*(rvalue: ptr Rvalue): ptr GObject {.cdecl,
    importc: "gcc_jit_rvalue_as_object", dynlib: gccdll.}
proc rvalueGetType*(rvalue: ptr Rvalue): ptr GType {.cdecl,
    importc: "gcc_jit_rvalue_get_type", dynlib: gccdll.}
## Integer constants.

proc contextNewRvalueFromInt*(ctxt: ptr GContext; numericType: ptr GType;
                              value: cint): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_rvalue_from_int", dynlib: gccdll.}
proc contextNewRvalueFromLong*(ctxt: ptr GContext; numericType: ptr GType;
                               value: clong): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_rvalue_from_long", dynlib: gccdll.}
proc contextZero*(ctxt: ptr GContext; numericType: ptr GType): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_zero", dynlib: gccdll.}
proc contextOne*(ctxt: ptr GContext; numericType: ptr GType): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_one", dynlib: gccdll.}


## Floating-point constants.

proc contextNewRvalueFromDouble*(ctxt: ptr GContext; numericType: ptr GType;
                                 value: cdouble): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_rvalue_from_double", dynlib: gccdll.}


## Pointers.

proc contextNewRvalueFromPtr*(ctxt: ptr GContext; pointerType: ptr GType;
                              value: pointer): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_rvalue_from_ptr", dynlib: gccdll.}
proc contextNull*(ctxt: ptr GContext; pointerType: ptr GType): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_null", dynlib: gccdll.}

proc contextNewStringLiteral*(ctxt: ptr GContext; value: cstring): ptr Rvalue {.
    cdecl, importc: "gcc_jit_context_new_string_literal", dynlib: gccdll.}
  ## String literals.

type
  UnaryOp* {.size: sizeof(cint).} = enum ## Negate an arithmetic value; analogous to:
                                          ## -(EXPR)
                                          ## in C.
    UNARY_OP_MINUS, ## Bitwise negation of an integer value (one's complement); analogous
                     ## to:
                     ## ~(EXPR)
                     ## in C.
    UNARY_OP_BITWISE_NEGATE, ## Logical negation of an arithmetic or pointer value; analogous to:
                              ## !(EXPR)
                              ## in C.
    UNARY_OP_LOGICAL_NEGATE, ## Absolute value of an arithmetic expression; analogous to:
                              ## abs (EXPR)
                              ## in C.
    UNARY_OP_ABS


proc contextNewUnaryOp*(ctxt: ptr GContext; loc: ptr GLocation; op: UnaryOp;
                        resultType: ptr GType; rvalue: ptr Rvalue): ptr Rvalue {.
    cdecl, importc: "gcc_jit_context_new_unary_op", dynlib: gccdll.}

type
  BinaryOp* {.size: sizeof(cint).} = enum ## Addition of arithmetic values; analogous to:
                                           ## (EXPR_A) + (EXPR_B)
                                           ## in C.
                                           ## For pointer addition, use gcc_jit_context_new_array_access.
    BINARY_OP_PLUS,         ## Subtraction of arithmetic values; analogous to:
                             ## (EXPR_A) - (EXPR_B)
                             ## in C.
    BINARY_OP_MINUS, ## Multiplication of a pair of arithmetic values; analogous to:
                      ## (EXPR_A) * (EXPR_B)
                      ## in C.
    BINARY_OP_MULT, ## Quotient of division of arithmetic values; analogous to:
                     ## (EXPR_A) / (EXPR_B)
                     ## in C.
                     ## The result type affects the kind of division: if the result type is
                     ## integer-based, then the result is truncated towards zero, whereas
                     ## a floating-point result type indicates floating-point division.
    BINARY_OP_DIVIDE, ## Remainder of division of arithmetic values; analogous to:
                       ## (EXPR_A) % (EXPR_B)
                       ## in C.
    BINARY_OP_MODULO,       ## Bitwise AND; analogous to:
                             ## (EXPR_A) & (EXPR_B)
                             ## in C.
    BINARY_OP_BITWISE_AND,  ## Bitwise exclusive OR; analogous to:
                             ## (EXPR_A) ^ (EXPR_B)
                             ## in C.
    BINARY_OP_BITWISE_XOR,  ## Bitwise inclusive OR; analogous to:
                             ## (EXPR_A) | (EXPR_B)
                             ## in C.
    BINARY_OP_BITWISE_OR,   ## Logical AND; analogous to:
                             ## (EXPR_A) && (EXPR_B)
                             ## in C.
    BINARY_OP_LOGICAL_AND,  ## Logical OR; analogous to:
                             ## (EXPR_A) || (EXPR_B)
                             ## in C.
    BINARY_OP_LOGICAL_OR,   ## Left shift; analogous to:
                             ## (EXPR_A) << (EXPR_B)
                             ## in C.
    BINARY_OP_LSHIFT,       ## Right shift; analogous to:
                             ## (EXPR_A) >> (EXPR_B)
                             ## in C.
    BINARY_OP_RSHIFT


proc contextNewBinaryOp*(ctxt: ptr GContext; loc: ptr GLocation; op: BinaryOp;
                         resultType: ptr GType; a: ptr Rvalue; b: ptr Rvalue): ptr Rvalue {.
    cdecl, importc: "gcc_jit_context_new_binary_op", dynlib: gccdll.}


type
  Comparison* {.size: sizeof(cint).} = enum ## \
    ## (Comparisons are treated as separate from "binary_op" to save
    ## you having to specify the result_type).
    COMPARISON_EQ, ## (EXPR_A) == (EXPR_B).
    COMPARISON_NE, ## (EXPR_A) != (EXPR_B).
    COMPARISON_LT, ## (EXPR_A) < (EXPR_B).
    COMPARISON_LE, ## (EXPR_A) <=(EXPR_B).
    COMPARISON_GT, ## (EXPR_A) > (EXPR_B).
    COMPARISON_GE  ## (EXPR_A) >= (EXPR_B).


proc contextNewComparison*(ctxt: ptr GContext; loc: ptr GLocation; op: Comparison;
                           a: ptr Rvalue; b: ptr Rvalue): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_comparison", dynlib: gccdll.}

## Function calls.

proc contextNewCall*(ctxt: ptr GContext; loc: ptr GLocation; `func`: ptr Function;
                     numargs: cint; args: ptr UncheckedArray[ptr Rvalue]): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_call", dynlib: gccdll.}
  ## Call of a specific function.

proc contextNewCallThroughPtr*(ctxt: ptr GContext; loc: ptr GLocation;
                               fnPtr: ptr Rvalue; numargs: cint;
                               args: ptr UncheckedArray[ptr Rvalue]): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_call_through_ptr", dynlib: gccdll.}
  ## Call through a function pointer.


proc contextNewCast*(ctxt: ptr GContext; loc: ptr GLocation; rvalue: ptr Rvalue;
                     `type`: ptr GType): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_cast", dynlib: gccdll.}
  ## GType-coercion.
  ##
  ## Currently only a limited set of conversions are possible:
  ## int <-> float
  ## int <-> bool

proc contextNewBitcast*(ctxt: ptr GContext; loc: ptr GLocation;
                        rvalue: ptr Rvalue; `type`: ptr GType): ptr Rvalue {.
    cdecl, importc: "gcc_jit_context_new_bitcast", dynlib: gccdll.}
  ## Reinterpret a value as another type.
  ##
  ## The types must be of the same size.

proc lvalueSetAlignment*(lvalue: ptr Lvalue; bytes: cuint) {.cdecl,
    importc: "gcc_jit_lvalue_set_alignment", dynlib: gccdll.}
  ## Set the alignment of a variable.

proc lvalueGetAlignment*(lvalue: ptr Lvalue): cuint {.cdecl,
    importc: "gcc_jit_lvalue_get_alignment", dynlib: gccdll.}
  ## Get the alignment of a variable.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_24; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_ALIGNMENT

proc contextNewArrayAccess*(ctxt: ptr GContext; loc: ptr GLocation;
                            `ptr`: ptr Rvalue; index: ptr Rvalue): ptr Lvalue {.
    cdecl, importc: "gcc_jit_context_new_array_access", dynlib: gccdll.}

proc lvalueAccessField*(structOrUnion: ptr Lvalue; loc: ptr GLocation;
                        field: ptr Field): ptr Lvalue {.cdecl,
    importc: "gcc_jit_lvalue_access_field", dynlib: gccdll.}
  ## Field access is provided separately for both lvalues and rvalues.
  ## Accessing a field of an lvalue of struct type, analogous to:
  ## (EXPR).field = ...;
  ## in C.

proc rvalueAccessField*(structOrUnion: ptr Rvalue; loc: ptr GLocation;
                        field: ptr Field): ptr Rvalue {.cdecl,
    importc: "gcc_jit_rvalue_access_field", dynlib: gccdll.}
  ## Accessing a field of an rvalue of struct type, analogous to:
  ## (EXPR).field
  ## in C.

proc rvalueDereferenceField*(`ptr`: ptr Rvalue; loc: ptr GLocation;
                             field: ptr Field): ptr Lvalue {.cdecl,
    importc: "gcc_jit_rvalue_dereference_field", dynlib: gccdll.}
  ## Accessing a field of an rvalue of pointer type, analogous to:
  ## (EXPR)->field
  ## in C, itself equivalent to (*EXPR).FIELD


proc rvalueDereference*(rvalue: ptr Rvalue; loc: ptr GLocation): ptr Lvalue {.
    cdecl, importc: "gcc_jit_rvalue_dereference", dynlib: gccdll.}
  ## Dereferencing a pointer; analogous to:
  ## (EXPR)
  ##
proc lvalueGetAddress*(lvalue: ptr Lvalue; loc: ptr GLocation): ptr Rvalue {.
    cdecl, importc: "gcc_jit_lvalue_get_address", dynlib: gccdll.}
  ## Taking the address of an lvalue; analogous to:
  ## &(EXPR)
  ## in C.

proc lvalueSetTlsModel*(lvalue: ptr Lvalue; model: TlsModel) {.cdecl,
    importc: "gcc_jit_lvalue_set_tls_model", dynlib: gccdll.}
  ## Set the thread-local storage model of a global variable

proc lvalueSetLinkSection*(lvalue: ptr Lvalue; sectionName: cstring) {.cdecl,
    importc: "gcc_jit_lvalue_set_link_section", dynlib: gccdll.}
  ## Set the link section of a global variable; analogous to:
  ## __attribute__((section(".section_name")))
  ## in C.

proc lvalueSetRegisterName*(lvalue: ptr Lvalue; regName: cstring) {.cdecl,
    importc: "gcc_jit_lvalue_set_register_name", dynlib: gccdll.}
  ## Make this variable a register variable and set its register name.

proc functionNewLocal*(`func`: ptr Function; loc: ptr GLocation;
                       `type`: ptr GType; name: cstring): ptr Lvalue {.cdecl,
    importc: "gcc_jit_function_new_local", dynlib: gccdll.}

## ********************************************************************
## Statement-creation.
## ********************************************************************
## Add evaluation of an rvalue, discarding the result
## (e.g. a function call that "returns" void).
##
## This is equivalent to this C code:
##
## (void)expression;
##

proc blockAddEval*(`block`: ptr GBlock; loc: ptr GLocation; rvalue: ptr Rvalue) {.
    cdecl, importc: "gcc_jit_block_add_eval", dynlib: gccdll.}
  ## Add evaluation of an rvalue, assigning the result to the given
  ## lvalue.
  ##
  ## This is roughly equivalent to this C code:
  ##
  ## lvalue = rvalue;
  ##

proc blockAddAssignment*(`block`: ptr GBlock; loc: ptr GLocation;
                         lvalue: ptr Lvalue; rvalue: ptr Rvalue) {.cdecl,
    importc: "gcc_jit_block_add_assignment", dynlib: gccdll.}
  ## Add evaluation of an rvalue, using the result to modify an
  ## lvalue.
  ##
  ## This is analogous to "+=" and friends:
  ##
  ## lvalue += rvalue;
  ## lvalue *= rvalue;
  ## lvalue /= rvalue;
  ## etc

proc blockAddAssignmentOp*(`block`: ptr GBlock; loc: ptr GLocation;
                           lvalue: ptr Lvalue; op: BinaryOp; rvalue: ptr Rvalue) {.
    cdecl, importc: "gcc_jit_block_add_assignment_op", dynlib: gccdll.}

proc blockAddComment*(`block`: ptr GBlock; loc: ptr GLocation; text: cstring) {.
    cdecl, importc: "gcc_jit_block_add_comment", dynlib: gccdll.}
  ## Add a no-op textual comment to the internal representation of the
  ## code. It will be optimized away, but will be visible in the dumps
  ## seen via
  ## GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
  ## and
  ## GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE,
  ## and thus may be of use when debugging how your project's internal
  ## representation gets converted to the libgccjit IR.

proc blockEndWithConditional*(`block`: ptr GBlock; loc: ptr GLocation;
                              boolval: ptr Rvalue; onTrue: ptr GBlock;
                              onFalse: ptr GBlock) {.cdecl,
    importc: "gcc_jit_block_end_with_conditional", dynlib: gccdll.}
  ## Terminate a block by adding evaluation of an rvalue, branching on the
  ## result to the appropriate successor block.
  ##
  ## This is roughly equivalent to this C code:
  ##
  ## if (boolval)
  ## goto on_true;
  ## else
  ## goto on_false;
  ##
  ## block, boolval, on_true, and on_false must be non-NULL.

proc blockEndWithJump*(`block`: ptr GBlock; loc: ptr GLocation; target: ptr GBlock) {.
    cdecl, importc: "gcc_jit_block_end_with_jump", dynlib: gccdll.}
  ## Terminate a block by adding a jump to the given target block.
  ##
  ## This is roughly equivalent to this C code:
  ##
  ## goto target;
  ##


proc blockEndWithReturn*(`block`: ptr GBlock; loc: ptr GLocation;
                         rvalue: ptr Rvalue) {.cdecl,
    importc: "gcc_jit_block_end_with_return", dynlib: gccdll.}
  ## Terminate a block by adding evaluation of an rvalue, returning the value.
  ##
  ## This is roughly equivalent to this C code:
  ##
  ## return expression;

proc blockEndWithVoidReturn*(`block`: ptr GBlock; loc: ptr GLocation) {.cdecl,
    importc: "gcc_jit_block_end_with_void_return", dynlib: gccdll.}
  ## Terminate a block by adding a valueless return, for use within a function
  ## with "void" return type.
  ##
  ## This is equivalent to this C code:
  ##
  ## return;
  ##

proc contextNewCase*(ctxt: ptr GContext; minValue: ptr Rvalue;
                     maxValue: ptr Rvalue; destBlock: ptr GBlock): ptr GCase {.
    cdecl, importc: "gcc_jit_context_new_case", dynlib: gccdll.}
  ## Create a new gcc_jit_case instance for use in a switch statement.
  ## min_value and max_value must be constants of integer type.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_3; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS

proc caseAsObject*(`case`: ptr GCase): ptr GObject {.cdecl,
    importc: "gcc_jit_case_as_object", dynlib: gccdll.}
  ## Upcasting from case to object.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_3; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS
  ##

proc blockEndWithSwitch*(`block`: ptr GBlock; loc: ptr GLocation;
                         expr: ptr Rvalue; defaultBlock: ptr GBlock;
                         numCases: cint; cases: ptr UncheckedArray[ptr GCase]) {.cdecl,
    importc: "gcc_jit_block_end_with_switch", dynlib: gccdll.}
  ## Terminate a block by adding evalation of an rvalue, then performing
  ## a multiway branch.
  ##
  ## This is roughly equivalent to this C code:
  ##
  ## switch (expr)
  ## {
  ## default:
  ## 	 goto default_block;
  ##
  ## case C0.min_value ... C0.max_value:
  ## 	 goto C0.dest_block;
  ##
  ## case C1.min_value ... C1.max_value:
  ## 	 goto C1.dest_block;
  ##
  ## ...etc...
  ##
  ## case C[N - 1].min_value ... C[N - 1].max_value:
  ## 	 goto C[N - 1].dest_block;
  ## }
  ##
  ## block, expr, default_block and cases must all be non-NULL.
  ##
  ## expr must be of the same integer type as all of the min_value
  ## and max_value within the cases.
  ##
  ## num_cases must be >= 0.
  ##
  ## The ranges of the cases must not overlap (or have duplicate
  ## values).
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_3; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_SWITCH_STATEMENTS

proc contextNewChildContext*(parentCtxt: ptr GContext): ptr GContext {.cdecl,
    importc: "gcc_jit_context_new_child_context", dynlib: gccdll.}
  ## ********************************************************************
  ## Nested contexts.
  ## ********************************************************************
  ## Given an existing JIT context, create a child context.
  ##
  ## The child inherits a copy of all option-settings from the parent.
  ##
  ## The child can reference objects created within the parent, but not
  ## vice-versa.
  ##
  ## The lifetime of the child context must be bounded by that of the
  ## parent: you should release a child context before releasing the parent
  ## context.
  ##
  ## If you use a function from a parent context within a child context,
  ## you have to compile the parent context before you can compile the
  ## child context, and the gcc_jit_result of the parent context must
  ## outlive the gcc_jit_result of the child context.
  ##
  ## This allows caching of shared initializations. For example, you could
  ## create types and declarations of global functions in a parent context
  ## once within a process, and then create child contexts whenever a
  ## function or loop becomes hot. Each such child context can be used for
  ## JIT-compiling just one function or loop, but can reference types
  ## and helper functions created within the parent context.
  ##
  ## Contexts can be arbitrarily nested, provided the above rules are
  ## followed, but it's probably not worth going above 2 or 3 levels, and
  ## there will likely be a performance hit for such nesting.

proc contextDumpReproducerToFile*(ctxt: ptr GContext; path: cstring) {.cdecl,
    importc: "gcc_jit_context_dump_reproducer_to_file", dynlib: gccdll.}
  ## ********************************************************************
  ## Implementation support.
  ## ********************************************************************
  ## Write C source code into "path" that can be compiled into a
  ## self-contained executable (i.e. with libgccjit as the only dependency).
  ## The generated code will attempt to replay the API calls that have been
  ## made into the given context.
  ##
  ## This may be useful when debugging the library or client code, for
  ## reducing a complicated recipe for reproducing a bug into a simpler
  ## form.
  ##
  ## Typically you need to supply the option "-Wno-unused-variable" when
  ## compiling the generated file (since the result of each API call is
  ## assigned to a unique variable within the generated C source, and not
  ## all are necessarily then used).

proc contextEnableDump*(ctxt: ptr GContext; dumpname: cstring;
                        outPtr: cstringArray) {.cdecl,
    importc: "gcc_jit_context_enable_dump", dynlib: gccdll.}
  ## Enable the dumping of a specific set of internal state from the
  ## compilation, capturing the result in-memory as a buffer.
  ##
  ## Parameter "dumpname" corresponds to the equivalent gcc command-line
  ## option, without the "-fdump-" prefix.
  ## For example, to get the equivalent of "-fdump-tree-vrp1", supply
  ## "tree-vrp1".
  ## The context directly stores the dumpname as a (const char *), so the
  ## passed string must outlive the context.
  ##
  ## gcc_jit_context_compile and gcc_jit_context_to_file
  ## will capture the dump as a dynamically-allocated buffer, writing
  ## it to ``*out_ptr``.
  ##
  ## The caller becomes responsible for calling
  ## free (*out_ptr)
  ## each time that gcc_jit_context_compile or gcc_jit_context_to_file
  ## are called. *out_ptr will be written to, either with the address of a
  ## buffer, or with NULL if an error occurred.
  ##
  ## This API entrypoint is likely to be less stable than the others.
  ## In particular, both the precise dumpnames, and the format and content
  ## of the dumps are subject to change.
  ##
  ## It exists primarily for writing the library's own test suite.

type
  Timer* {.bycopy.} = object

## ********************************************************************
## Timing support.
## ********************************************************************

proc timerNew*(): ptr Timer {.cdecl, importc: "gcc_jit_timer_new",
                              dynlib: gccdll.}
  ## Create a gcc_jit_timer instance, and start timing.

proc timerRelease*(timer: ptr Timer) {.cdecl, importc: "gcc_jit_timer_release",
                                       dynlib: gccdll.}
  ## Release a gcc_jit_timer instance.

proc contextSetTimer*(ctxt: ptr GContext; timer: ptr Timer) {.cdecl,
    importc: "gcc_jit_context_set_timer", dynlib: gccdll.}
  ## Associate a gcc_jit_timer instance with a context.

proc contextGetTimer*(ctxt: ptr GContext): ptr Timer {.cdecl,
    importc: "gcc_jit_context_get_timer", dynlib: gccdll.}
  ## Get the timer associated with a context (if any).

proc timerPush*(timer: ptr Timer; itemName: cstring) {.cdecl,
    importc: "gcc_jit_timer_push", dynlib: gccdll.}
  ## Push the given item onto the timing stack.

proc timerPop*(timer: ptr Timer; itemName: cstring) {.cdecl,
    importc: "gcc_jit_timer_pop", dynlib: gccdll.}
  ## Pop the top item from the timing stack.

proc timerPrint*(timer: ptr Timer; fOut: ptr File) {.cdecl,
    importc: "gcc_jit_timer_print", dynlib: gccdll.}
  ## Print timing information to the given stream about activity since
  ## the timer was started.

proc rvalueSetBoolRequireTailCall*(call: ptr Rvalue; requireTailCall: cint) {.
    cdecl, importc: "gcc_jit_rvalue_set_bool_require_tail_call", dynlib: gccdll.}
  ## Mark/clear a call as needing tail-call optimization.

proc typeGetAligned*(`type`: ptr GType; alignmentInBytes: csize_t): ptr GType {.
    cdecl, importc: "gcc_jit_type_get_aligned", dynlib: gccdll.}
  ## Given type "T", get type:
  ##
  ## T __attribute__ ((aligned (ALIGNMENT_IN_BYTES)))
  ##
  ## The alignment must be a power of two.

proc typeGetVector*(`type`: ptr GType; numUnits: csize_t): ptr GType {.cdecl,
    importc: "gcc_jit_type_get_vector", dynlib: gccdll.}
  ## Given type "T", get type:
  ##
  ## T  __attribute__ ((vector_size (sizeof(T) * num_units))
  ##
  ## T must be integral/floating point; num_units must be a power of two.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_8; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_type_get_vector
  ##

proc functionGetAddress*(fn: ptr Function; loc: ptr GLocation): ptr Rvalue {.
    cdecl, importc: "gcc_jit_function_get_address", dynlib: gccdll.}
  ## Get the address of a function as an rvalue, of function pointer
  ## type.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_9; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_function_get_address
  ##


proc contextNewRvalueFromVector*(ctxt: ptr GContext; loc: ptr GLocation;
                                 vecType: ptr GType; numElements: csize_t;
                                 elements: ptr UncheckedArray[ptr Rvalue]): ptr Rvalue {.cdecl,
    importc: "gcc_jit_context_new_rvalue_from_vector", dynlib: gccdll.}
  ## Build a vector rvalue from an array of elements.
  ##
  ## "vec_type" should be a vector type, created using gcc_jit_type_get_vector.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_10; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_context_new_rvalue_from_vector
  ##

proc versionMajor*(): cint {.cdecl, importc: "gcc_jit_version_major",
                             dynlib: gccdll.}
proc versionMinor*(): cint {.cdecl, importc: "gcc_jit_version_minor",
                             dynlib: gccdll.}
proc versionPatchlevel*(): cint {.cdecl, importc: "gcc_jit_version_patchlevel",
                                  dynlib: gccdll.}
  ## Functions to retrieve libgccjit version.
  ## Analogous to __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__ in C code.
  ##
  ## These API entrypoints were added in LIBGCCJIT_ABI_13; you can test for their
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_gcc_jit_version
  ##

proc blockAddExtendedAsm*(`block`: ptr GBlock; loc: ptr GLocation;
                          asmTemplate: cstring): ptr ExtendedAsm {.cdecl,
    importc: "gcc_jit_block_add_extended_asm", dynlib: gccdll.}
  ## ********************************************************************
  ## Asm support.
  ## ********************************************************************
  ## Functions for adding inline assembler code, analogous to GCC's
  ## "extended asm" syntax.
  ##
  ## See https://gcc.gnu.org/onlinedocs/gcc/Using-Assembly-Language-with-C.html
  ##
  ## These API entrypoints were added in LIBGCCJIT_ABI_15; you can test for their
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_ASM_STATEMENTS
  ##
  ## Create a gcc_jit_extended_asm for an extended asm statement
  ## with no control flow (i.e. without the goto qualifier).
  ##
  ## The asm_template parameter  corresponds to the AssemblerTemplate
  ## within C's extended asm syntax. It must be non-NULL.


proc blockEndWithExtendedAsmGoto*(`block`: ptr GBlock; loc: ptr GLocation;
                                  asmTemplate: cstring; numGotoBlocks: cint;
                                  gotoBlocks: ptr UncheckedArray[ptr GBlock];
                                  fallthroughBlock: ptr GBlock): ptr ExtendedAsm {.
    cdecl, importc: "gcc_jit_block_end_with_extended_asm_goto", dynlib: gccdll.}
  ## Create a gcc_jit_extended_asm for an extended asm statement
  ## that may perform jumps, and use it to terminate the given block.
  ## This is equivalent to the "goto" qualifier in C's extended asm
  ## syntax.

proc extendedAsmAsObject*(extAsm: ptr ExtendedAsm): ptr GObject {.cdecl,
    importc: "gcc_jit_extended_asm_as_object", dynlib: gccdll.}
  ## Upcasting from extended asm to object.

proc extendedAsmSetVolatileFlag*(extAsm: ptr ExtendedAsm; flag: cint) {.cdecl,
    importc: "gcc_jit_extended_asm_set_volatile_flag", dynlib: gccdll.}
  ## Set whether the gcc_jit_extended_asm has side-effects, equivalent to
  ## the "volatile" qualifier in C's extended asm syntax.

proc extendedAsmSetInlineFlag*(extAsm: ptr ExtendedAsm; flag: cint) {.cdecl,
    importc: "gcc_jit_extended_asm_set_inline_flag", dynlib: gccdll.}
  ## Set the equivalent of the "inline" qualifier in C's extended asm
  ## syntax.

proc extendedAsmAddOutputOperand*(extAsm: ptr ExtendedAsm;
                                  asmSymbolicName: cstring; constraint: cstring;
                                  dest: ptr Lvalue) {.cdecl,
    importc: "gcc_jit_extended_asm_add_output_operand", dynlib: gccdll.}
  ## Add an output operand to the extended asm statement.
  ## "asm_symbolic_name" can be NULL.
  ## "constraint" and "dest" must be non-NULL.
  ## This function can't be called on an "asm goto" as such instructions
  ## can't have outputs

proc extendedAsmAddInputOperand*(extAsm: ptr ExtendedAsm;
                                 asmSymbolicName: cstring; constraint: cstring;
                                 src: ptr Rvalue) {.cdecl,
    importc: "gcc_jit_extended_asm_add_input_operand", dynlib: gccdll.}
  ## Add an input operand to the extended asm statement.
  ## "asm_symbolic_name" can be NULL.
  ## "constraint" and "src" must be non-NULL.

proc extendedAsmAddClobber*(extAsm: ptr ExtendedAsm; victim: cstring) {.cdecl,
    importc: "gcc_jit_extended_asm_add_clobber", dynlib: gccdll.}
  ## Add "victim" to the list of registers clobbered by the extended
  ## asm statement. It must be non-NULL.

proc contextAddTopLevelAsm*(ctxt: ptr GContext; loc: ptr GLocation;
                            asmStmts: cstring) {.cdecl,
    importc: "gcc_jit_context_add_top_level_asm", dynlib: gccdll.}
  ## Add "asm_stmts", a set of top-level asm statements, analogous to
  ## those created by GCC's "basic" asm syntax in C at file scope.

proc functionGetReturnType*(`func`: ptr Function): ptr GType {.cdecl,
    importc: "gcc_jit_function_get_return_type", dynlib: gccdll.}
  ## Reflection functions to get the number of parameters, return type of
  ## a function and whether a type is a bool from the C API.
  ##
  ## This API entrypoint was added in LIBGCCJIT_ABI_16; you can test for its
  ## presence using
  ## #ifdef LIBGCCJIT_HAVE_REFLECTION
  ##
  ## Get the return type of a function.

proc functionGetParamCount*(`func`: ptr Function): csize_t {.cdecl,
    importc: "gcc_jit_function_get_param_count", dynlib: gccdll.}
  ## Get the number of params of a function.

proc typeDyncastArray*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_dyncast_array", dynlib: gccdll.}
  ## Get the element type of an array type or NULL if it's not an array.

proc typeIsBool*(`type`: ptr GType): cint {.cdecl,
    importc: "gcc_jit_type_is_bool", dynlib: gccdll.}
  ## Return non-zero if the type is a bool.

proc typeDyncastFunctionPtrType*(`type`: ptr GType): ptr FunctionType {.cdecl,
    importc: "gcc_jit_type_dyncast_function_ptr_type", dynlib: gccdll.}
  ## Return the function type if it is one or NULL.

proc functionTypeGetReturnType*(functionType: ptr FunctionType): ptr GType {.
    cdecl, importc: "gcc_jit_function_type_get_return_type", dynlib: gccdll.}
  ## Given a function type, return its return type.

proc functionTypeGetParamCount*(functionType: ptr FunctionType): csize_t {.
    cdecl, importc: "gcc_jit_function_type_get_param_count", dynlib: gccdll.}
  ## Given a function type, return its number of parameters.

proc functionTypeGetParamType*(functionType: ptr FunctionType; index: csize_t): ptr GType {.
    cdecl, importc: "gcc_jit_function_type_get_param_type", dynlib: gccdll.}
  ## Given a function type, return the type of the specified parameter.

proc typeIsIntegral*(`type`: ptr GType): cint {.cdecl,
    importc: "gcc_jit_type_is_integral", dynlib: gccdll.}
  ## Return non-zero if the type is an integral.

proc typeIsPointer*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_is_pointer", dynlib: gccdll.}
  ## Return the type pointed by the pointer type or NULL if it's not a
  ## pointer.

proc typeDyncastVector*(`type`: ptr GType): ptr VectorType {.cdecl,
    importc: "gcc_jit_type_dyncast_vector", dynlib: gccdll.}
  ## Given a type, return a dynamic cast to a vector type or NULL.

proc typeIsStruct*(`type`: ptr GType): ptr Struct {.cdecl,
    importc: "gcc_jit_type_is_struct", dynlib: gccdll.}
  ## Given a type, return a dynamic cast to a struct type or NULL.

proc vectorTypeGetNumUnits*(vectorType: ptr VectorType): csize_t {.cdecl,
    importc: "gcc_jit_vector_type_get_num_units", dynlib: gccdll.}
  ## Given a vector type, return the number of units it contains.

proc vectorTypeGetElementType*(vectorType: ptr VectorType): ptr GType {.cdecl,
    importc: "gcc_jit_vector_type_get_element_type", dynlib: gccdll.}
  ## Given a vector type, return the type of its elements.

proc typeUnqualified*(`type`: ptr GType): ptr GType {.cdecl,
    importc: "gcc_jit_type_unqualified", dynlib: gccdll.}
  ## Given a type, return the unqualified type, removing "const", "volatile"
  ## and alignment qualifiers.
