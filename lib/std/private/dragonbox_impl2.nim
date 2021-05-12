{.compile: "dragonbox_impl.cc".}
const DtoaMinBufferLength* = 64
proc dragonboxToString*(buffer: ptr char, value: cdouble): ptr char {.importc: "nim_dragonbox_Dtoa".}

# when isMainModule:
#   var buffer: array[DtoaMinBufferLength, char]
#   let s = dragonboxToString(buffer[0].addr, 1.23)
#   echo buffer
#   echo "ok1"
