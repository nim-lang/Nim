# Backend for the different user interfaces.

proc myAdd*(x, y: int): int {.cdecl, exportc.} = 
  result = x + y

