type
  Ty* {.deprecated.} = uint32
  Ty1* {.deprecated: "hello".} = uint32

var aVar* {.deprecated.}: char

proc aProc*() {.deprecated.} = discard
proc aProc1*() {.deprecated: "hello".} = discard

{.deprecated: "goodbye".}
