# Backend for the Lazarus GUI

proc myAdd*(x, y: int): int {.cdecl, exportc.} = 
  result = x + y

