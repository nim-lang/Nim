proc add*(a, b: int): int {.cdecl, exportc.} =
    a + b
proc sub*(a, b: int): int {.cdecl, exportc.} =
    a - b