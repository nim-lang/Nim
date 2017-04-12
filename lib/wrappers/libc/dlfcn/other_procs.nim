proc dlclose*(a1: pointer): cint {.importc, header: "<dlfcn.h>".}
proc dlerror*(): cstring {.importc, header: "<dlfcn.h>".}
proc dlopen*(a1: cstring, a2: cint): pointer {.importc, header: "<dlfcn.h>".}
proc dlsym*(a1: pointer, a2: cstring): pointer {.importc, header: "<dlfcn.h>".}
