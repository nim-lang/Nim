discard """
disabled:true
"""

import dynlib

proc dlclose(lib: LibHandle):cint {.importc, header: "<dlfcn.h>".}
proc dlerror(): cstring {.importc, header: "<dlfcn.h>".}

proc main()=
  var libHandle: LibHandle
  doAssertRaises(LibraryError):
    if dlclose(libHandle) != 0:
      raise newException(LibraryError, $dlerror())
  doAssertRaises(LibraryError):
    unloadLib(libHandle)
main()
