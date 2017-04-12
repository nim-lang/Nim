proc creat*(a1: cstring, a2: Mode): cint {.importc, header: "<fcntl.h>".}
proc fcntl*(a1: cint | SocketHandle, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc open*(a1: cstring, a2: cint): cint {.varargs, importc, header: "<fcntl.h>".}
proc posix_fadvise*(a1: cint, a2, a3: Off, a4: cint): cint {.
  importc, header: "<fcntl.h>".}
proc posix_fallocate*(a1: cint, a2, a3: Off): cint {.
  importc, header: "<fcntl.h>".}
