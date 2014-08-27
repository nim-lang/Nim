#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the ability to access symbols from shared
## libraries. On POSIX this uses the ``dlsym`` mechanism, on 
## Windows ``LoadLibrary``. 

type
  LibHandle* = pointer ## a handle to a dynamically loaded library

{.deprecated: [TLibHandle: LibHandle].}

proc loadLib*(path: string, global_symbols=false): LibHandle
  ## loads a library from `path`. Returns nil if the library could not 
  ## be loaded.

proc loadLib*(): LibHandle
  ## gets the handle from the current executable. Returns nil if the 
  ## library could not be loaded.

proc unloadLib*(lib: LibHandle)
  ## unloads the library `lib`

proc raiseInvalidLibrary*(name: cstring) {.noinline, noreturn.} =
  ## raises an `EInvalidLibrary` exception.
  var e: ref LibraryError
  new(e)
  e.msg = "could not find symbol: " & $name
  raise e

proc symAddr*(lib: LibHandle, name: cstring): pointer
  ## retrieves the address of a procedure/variable from `lib`. Returns nil
  ## if the symbol could not be found.

proc checkedSymAddr*(lib: LibHandle, name: cstring): pointer =
  ## retrieves the address of a procedure/variable from `lib`. Raises
  ## `EInvalidLibrary` if the symbol could not be found.
  result = symAddr(lib, name)
  if result == nil: raiseInvalidLibrary(name)

when defined(posix):
  #
  # =========================================================================
  # This is an implementation based on the dlfcn interface.
  # The dlfcn interface is available in Linux, SunOS, Solaris, IRIX, FreeBSD,
  # NetBSD, AIX 4.2, HPUX 11, and probably most other Unix flavors, at least
  # as an emulation layer on top of native functions.
  # =========================================================================
  #
  var
    RTLD_NOW {.importc: "RTLD_NOW", header: "<dlfcn.h>".}: int
    RTLD_GLOBAL {.importc: "RTLD_GLOBAL", header: "<dlfcn.h>".}: int

  proc dlclose(lib: TLibHandle) {.importc, header: "<dlfcn.h>".}
  proc dlopen(path: CString, mode: int): TLibHandle {.
      importc, header: "<dlfcn.h>".}
  proc dlsym(lib: TLibHandle, name: cstring): pointer {.
      importc, header: "<dlfcn.h>".}

  proc loadLib(path: string, global_symbols=false): TLibHandle = 
    var flags = RTLD_NOW
    if global_symbols: flags = flags or RTLD_GLOBAL
    return dlopen(path, flags)
  proc loadLib(): TLibHandle = return dlopen(nil, RTLD_NOW)
  proc unloadLib(lib: TLibHandle) = dlclose(lib)
  proc symAddr(lib: TLibHandle, name: cstring): pointer = 
    return dlsym(lib, name)

elif defined(windows) or defined(dos):
  #
  # =======================================================================
  # Native Windows Implementation
  # =======================================================================
  #
  type
    THINSTANCE {.importc: "HINSTANCE".} = pointer

  proc FreeLibrary(lib: THINSTANCE) {.importc, header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): THINSTANCE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}
  proc getProcAddress(lib: THINSTANCE, name: cstring): pointer {.
      importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc loadLib(path: string, global_symbols=false): LibHandle =
    result = cast[LibHandle](winLoadLibrary(path))
  proc loadLib(): LibHandle =
    result = cast[LibHandle](winLoadLibrary(nil))
  proc unloadLib(lib: LibHandle) = FreeLibrary(cast[THINSTANCE](lib))

  proc symAddr(lib: LibHandle, name: cstring): pointer =
    result = getProcAddress(cast[THINSTANCE](lib), name)

else:
  {.error: "no implementation for dynlib".}
