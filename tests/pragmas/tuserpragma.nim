discard """
  file: "tuserpragma.nim"
"""

{.pragma: rtl, cdecl, exportc.}

proc myproc(x, y: int): int {.rtl} =
  nil
