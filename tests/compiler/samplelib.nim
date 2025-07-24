# Sample library used by tcmdlineclib.nim
proc test(): int {.cdecl, exportc, dynlib.} = 123
