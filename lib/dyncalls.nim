#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


#
# This file implements the ability to call native procs from libraries.
# It is not possible to do this in a platform independant way, unfortunately.
# However, the interface has been designed to take platform differences into
# account and been ported to all major platforms.
#
# interface

type
  EInvalidLibrary = object of EOS

when defined(windows) or defined(dos):
  {.define: USE_DLL.}
elif defined(posix):
  {.define: USE_DLOPEN.}
elif defined(mac):
  {.define: USE_DYLD.}

type
  TLibHandle = pointer       # private type
  TProcAddr = pointer        # libary loading and loading of procs:

const
  NilLibHandle: TLibHandle = nil

proc nimLoadLibrary(path: string): TLibHandle {.compilerproc.}
proc nimUnloadLibrary(lib: TLibHandle) {.compilerproc.}
proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr {.compilerproc.}

#implementation

# this code was inspired from Lua's source code:
# Lua - An Extensible Extension Language
# Tecgraf: Computer Graphics Technology Group, PUC-Rio, Brazil
# http://www.lua.org
# mailto:info@lua.org

when defined(USE_DLOPEN):
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
  proc dlopen(path: CString, mode: int): TLibHandle {.
      importc, header: "<dlfcn.h>".}
  proc dlsym(lib: TLibHandle, name: cstring): TProcAddr {.
      importc, header: "<dlfcn.h>".}

  proc nimUnloadLibrary(lib: TLibHandle) =
    dlclose(lib)

  proc nimLoadLibrary(path: string): TLibHandle =
    result = dlopen(path, RTLD_NOW)
    if result == nil:
      raise newException(EInvalidLibrary, "could not load: " & path)

  proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr =
    result = dlsym(lib, name)

elif defined(USE_DLL):
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
  proc GetProcAddress(lib: THINSTANCE, name: cstring): TProcAddr {.
      importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc nimUnloadLibrary(lib: TLibHandle) =
    FreeLibrary(cast[THINSTANCE](lib))

  proc nimLoadLibrary(path: string): TLibHandle =
    result = cast[TLibHandle](winLoadLibrary(path))
    if result == nil: 
      raise newException(EInvalidLibrary, "could not load: " & path)

  proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr =
    result = GetProcAddress(cast[THINSTANCE](lib), name)

elif defined(USE_DYLD):
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
        if result == nil:
          raise newException(EInvalidLibrary, "could not load: " & path)

  proc nimGetProcAddr(lib: TLibHandle, cname: string): TProcAddr =
    var
      nss: NSSymbol
    nss = NSLookupSymbolInModule(NSModule(lib), name)
    result = TProcAddr(NSAddressOfSymbol(nss))

else: # workaround a newly introduced bug :-(
  {.error: "no implementation for dyncalls".}
