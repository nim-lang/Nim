import std/bitops

proc exit*(code: int) {.importc, header: "<stdlib.h>", cdecl.}

proc hwWrite*(x: uint8): uint8 = x.rotateLeftBits(1)
