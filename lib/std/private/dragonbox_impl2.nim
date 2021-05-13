import dependency_utils
static: addDependency("dragonbox")
const DtoaMinBufferLength* = 64
proc dragonboxToString*(buffer: ptr char, value: cdouble): ptr char {.importc: "nim_dragonbox_Dtoa".}
