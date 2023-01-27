proc test(): int {.importc, cdecl.}

doAssert test() == 123
