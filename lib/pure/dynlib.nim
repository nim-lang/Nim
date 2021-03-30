#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the ability to access symbols from shared
## libraries. On POSIX this uses the `dlsym` mechanism, on
## Windows `LoadLibrary`.
##
## Examples
## ========
##
## Loading a simple C function
## ---------------------------
##
## The following example demonstrates loading a function called 'greet'
## from a library that is determined at runtime based upon a language choice.
## If the library fails to load or the function 'greet' is not found,
## it quits with a failure error code.
##
## .. code-block::nim
##
##   import std/dynlib
##
##   type
##     greetFunction = proc(): cstring {.gcsafe, stdcall.}
##
##   let lang = stdin.readLine()
##
##   let lib = case lang
##   of "french":
##     loadLib("french.dll")
##   else:
##     loadLib("english.dll")
##
##   if lib == nil:
##     echo "Error loading library"
##     quit(QuitFailure)
##
##   let greet = cast[greetFunction](lib.symAddr("greet"))
##
##   if greet == nil:
##     echo "Error loading 'greet' function from library"
##     quit(QuitFailure)
##
##   let greeting = greet()
##
##   echo greeting
##
##   unloadLib(lib)
##

import strutils

type
  LibHandle* = pointer ## a handle to a dynamically loaded library

proc loadLib*(path: string, globalSymbols = false): LibHandle {.gcsafe.}
  ## loads a library from `path`. Returns nil if the library could not
  ## be loaded.

proc loadLib*(): LibHandle {.gcsafe.}
  ## gets the handle from the current executable. Returns nil if the
  ## library could not be loaded.

proc unloadLib*(lib: LibHandle) {.gcsafe.}
  ## unloads the library `lib`

proc raiseInvalidLibrary*(name: cstring) {.noinline, noreturn.} =
  ## raises an `EInvalidLibrary` exception.
  raise newException(LibraryError, "could not find symbol: " & $name)

proc symAddr*(lib: LibHandle, name: cstring): pointer {.gcsafe.}
  ## retrieves the address of a procedure/variable from `lib`. Returns nil
  ## if the symbol could not be found.

proc checkedSymAddr*(lib: LibHandle, name: cstring): pointer =
  ## retrieves the address of a procedure/variable from `lib`. Raises
  ## `EInvalidLibrary` if the symbol could not be found.
  result = symAddr(lib, name)
  if result == nil: raiseInvalidLibrary(name)

proc libCandidates*(s: string, dest: var seq[string]) =
  ## given a library name pattern `s` write possible library names to `dest`.
  var le = strutils.find(s, '(')
  var ri = strutils.find(s, ')', le+1)
  if le >= 0 and ri > le:
    var prefix = substr(s, 0, le - 1)
    var suffix = substr(s, ri + 1)
    for middle in split(substr(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else:
    add(dest, s)

proc loadLibPattern*(pattern: string, globalSymbols = false): LibHandle =
  ## loads a library with name matching `pattern`, similar to what `dynlib`
  ## pragma does. Returns nil if the library could not be loaded.
  ## Warning: this proc uses the GC and so cannot be used to load the GC.
  var candidates = newSeq[string]()
  libCandidates(pattern, candidates)
  for c in candidates:
    result = loadLib(c, globalSymbols)
    if not result.isNil: break

when defined(posix) and not defined(nintendoswitch):
  #
  # =========================================================================
  # This is an implementation based on the dlfcn interface.
  # The dlfcn interface is available in Linux, SunOS, Solaris, IRIX, FreeBSD,
  # NetBSD, AIX 4.2, HPUX 11, and probably most other Unix flavors, at least
  # as an emulation layer on top of native functions.
  # =========================================================================
  #
  import posix

  proc loadLib(path: string, globalSymbols = false): LibHandle =
    let flags =
      if globalSymbols: RTLD_NOW or RTLD_GLOBAL
      else: RTLD_NOW

    dlopen(path, flags)

  proc loadLib(): LibHandle = dlopen(nil, RTLD_NOW)
  proc unloadLib(lib: LibHandle) = discard dlclose(lib)
  proc symAddr(lib: LibHandle, name: cstring): pointer = dlsym(lib, name)

elif defined(nintendoswitch):
  #
  # =========================================================================
  # Nintendo switch DevkitPro sdk does not have these. Raise an error if called.
  # =========================================================================
  #

  proc dlclose(lib: LibHandle) =
    raise newException(OSError, "dlclose not implemented on Nintendo Switch!")
  proc dlopen(path: cstring, mode: int): LibHandle =
    raise newException(OSError, "dlopen not implemented on Nintendo Switch!")
  proc dlsym(lib: LibHandle, name: cstring): pointer =
    raise newException(OSError, "dlsym not implemented on Nintendo Switch!")
  proc loadLib(path: string, global_symbols = false): LibHandle =
    raise newException(OSError, "loadLib not implemented on Nintendo Switch!")
  proc loadLib(): LibHandle =
    raise newException(OSError, "loadLib not implemented on Nintendo Switch!")
  proc unloadLib(lib: LibHandle) =
    raise newException(OSError, "unloadLib not implemented on Nintendo Switch!")
  proc symAddr(lib: LibHandle, name: cstring): pointer =
    raise newException(OSError, "symAddr not implemented on Nintendo Switch!")

elif defined(windows) or defined(dos):
  #
  # =======================================================================
  # Native Windows Implementation
  # =======================================================================
  #
  type
    HMODULE {.importc: "HMODULE".} = pointer
    FARPROC {.importc: "FARPROC".} = pointer

  proc FreeLibrary(lib: HMODULE) {.importc, header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): HMODULE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}
  proc getProcAddress(lib: HMODULE, name: cstring): FARPROC {.
      importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc loadLib(path: string, globalSymbols = false): LibHandle =
    result = cast[LibHandle](winLoadLibrary(path))
  proc loadLib(): LibHandle =
    result = cast[LibHandle](winLoadLibrary(nil))
  proc unloadLib(lib: LibHandle) = FreeLibrary(cast[HMODULE](lib))

  proc symAddr(lib: LibHandle, name: cstring): pointer =
    result = cast[pointer](getProcAddress(cast[HMODULE](lib), name))

else:
  {.error: "no implementation for dynlib".}
