#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the ability to call native procs from libraries.
# It is not possible to do this in a platform independent way, unfortunately.
# However, the interface has been designed to take platform differences into
# account and been ported to all major platforms.

{.push stack_trace: off.}

const
  NilLibHandle: LibHandle = nil

proc rawWrite(f: File, s: string) =
  # we cannot throw an exception here!
  discard writeBuffer(f, cstring(s), s.len)

proc nimLoadLibraryError(path: string) =
  # carefully written to avoid memory allocation:
  stdout.rawWrite("could not load: ")
  stdout.rawWrite(path)
  stdout.rawWrite("\n")
  quit(1)

proc procAddrError(name: cstring) {.noinline.} =
  # carefully written to avoid memory allocation:
  stdout.rawWrite("could not import: ")
  stdout.write(name)
  stdout.rawWrite("\n")
  quit(1)

# this code was inspired from Lua's source code:
# Lua - An Extensible Extension Language
# Tecgraf: Computer Graphics Technology Group, PUC-Rio, Brazil
# http://www.lua.org
# mailto:info@lua.org

when defined(posix):
  #
  # =========================================================================
  # This is an implementation based on the dlfcn interface.
  # The dlfcn interface is available in Linux, SunOS, Solaris, IRIX, FreeBSD,
  # NetBSD, AIX 4.2, HPUX 11, and probably most other Unix flavors, at least
  # as an emulation layer on top of native functions.
  # =========================================================================
  #

  # c stuff:
  var
    RTLD_NOW {.importc: "RTLD_NOW", header: "<dlfcn.h>".}: int

  proc dlclose(lib: LibHandle) {.importc, header: "<dlfcn.h>".}
  proc dlopen(path: cstring, mode: int): LibHandle {.
      importc, header: "<dlfcn.h>".}
  proc dlsym(lib: LibHandle, name: cstring): ProcAddr {.
      importc, header: "<dlfcn.h>".}

  proc dlerror(): cstring {.importc, header: "<dlfcn.h>".}

  proc nimUnloadLibrary(lib: LibHandle) =
    dlclose(lib)

  proc nimLoadLibrary(path: string): LibHandle =
    result = dlopen(path, RTLD_NOW)
    when defined(nimDebugDlOpen):
      let error = dlerror()
      if error != nil:
        c_fprintf(c_stdout, "%s\n", error)

  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr =
    result = dlsym(lib, name)
    if result == nil: procAddrError(name)

elif defined(windows) or defined(dos):
  #
  # =======================================================================
  # Native Windows Implementation
  # =======================================================================
  #
  when defined(cpp):
    type
      THINSTANCE {.importc: "HINSTANCE".} = object
        x: pointer
    proc getProcAddress(lib: THINSTANCE, name: cstring): ProcAddr {.
        importcpp: "(void*)GetProcAddress(@)", header: "<windows.h>", stdcall.}
  else:
    type
      THINSTANCE {.importc: "HINSTANCE".} = pointer
    proc getProcAddress(lib: THINSTANCE, name: cstring): ProcAddr {.
        importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc freeLibrary(lib: THINSTANCE) {.
      importc: "FreeLibrary", header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): THINSTANCE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}

  proc nimUnloadLibrary(lib: LibHandle) =
    freeLibrary(cast[THINSTANCE](lib))

  proc nimLoadLibrary(path: string): LibHandle =
    result = cast[LibHandle](winLoadLibrary(path))

  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr =
    result = getProcAddress(cast[THINSTANCE](lib), name)
    if result != nil: return
    for i in countup(0, 50):
      var decorated = "_" & $name & "@" & $(i * 4)
      result = getProcAddress(cast[THINSTANCE](lib), cstring(decorated))
      if result != nil: return
    procAddrError(name)

else:
  {.error: "no implementation for dyncalls".}

{.pop.}
