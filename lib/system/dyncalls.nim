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
  NilLibHandle: TLibHandle = nil

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

  proc dlclose(lib: TLibHandle) {.importc, header: "<dlfcn.h>".}
  proc dlopen(path: cstring, mode: int): TLibHandle {.
      importc, header: "<dlfcn.h>".}
  proc dlsym(lib: TLibHandle, name: cstring): TProcAddr {.
      importc, header: "<dlfcn.h>".}

  proc dlerror(): cstring {.importc, header: "<dlfcn.h>".}

  proc nimUnloadLibrary(lib: TLibHandle) =
    dlclose(lib)

  proc nimLoadLibrary(path: string): TLibHandle =
    result = dlopen(path, RTLD_NOW)
    #c_fprintf(c_stdout, "%s\n", dlerror())

  proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr =
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
    proc getProcAddress(lib: THINSTANCE, name: cstring): TProcAddr {.
        importcpp: "(void*)GetProcAddress(@)", header: "<windows.h>", stdcall.}
  else:
    type
      THINSTANCE {.importc: "HINSTANCE".} = pointer
    proc getProcAddress(lib: THINSTANCE, name: cstring): TProcAddr {.
        importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc freeLibrary(lib: THINSTANCE) {.
      importc: "FreeLibrary", header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): THINSTANCE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}

  proc nimUnloadLibrary(lib: TLibHandle) =
    freeLibrary(cast[THINSTANCE](lib))

  proc nimLoadLibrary(path: string): TLibHandle =
    result = cast[TLibHandle](winLoadLibrary(path))

  proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr =
    result = getProcAddress(cast[THINSTANCE](lib), name)
    if result == nil: procAddrError(name)

elif defined(mac):
  #
  # =======================================================================
  # Native Mac OS X / Darwin Implementation
  # =======================================================================
  #
  {.error: "no implementation for dyncalls yet".}

  proc nimUnloadLibrary(lib: TLibHandle) =
    NSUnLinkModule(NSModule(lib), NSUNLINKMODULE_OPTION_RESET_LAZY_REFERENCES)

  var
    dyld_present {.importc: "_dyld_present", header: "<dyld.h>".}: int

  proc nimLoadLibrary(path: string): TLibHandle =
    var
      img: NSObjectFileImage
      ret: NSObjectFileImageReturnCode
      modul: NSModule
    # this would be a rare case, but prevents crashing if it happens
    result = nil
    if dyld_present != 0:
      ret = NSCreateObjectFileImageFromFile(path, addr(img))
      if ret == NSObjectFileImageSuccess:
        modul = NSLinkModule(img, path, NSLINKMODULE_OPTION_PRIVATE or
                                        NSLINKMODULE_OPTION_RETURN_ON_ERROR)
        NSDestroyObjectFileImage(img)
        result = TLibHandle(modul)

  proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr =
    var
      nss: NSSymbol
    nss = NSLookupSymbolInModule(NSModule(lib), name)
    result = TProcAddr(NSAddressOfSymbol(nss))
    if result == nil: ProcAddrError(name)

else:
  {.error: "no implementation for dyncalls".}
  
{.pop.}

