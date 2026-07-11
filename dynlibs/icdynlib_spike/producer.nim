import icdynlib

proc answer*(x: cint): cint {.dynexport.} =
  x + 1

proc answer*(x, y: cint): cint {.dynexport.} =
  x + y

proc identity*(value: pointer): pointer {.dynexport.} =
  value

proc notify*(value: cuint) {.dynexport.} =
  discard value
